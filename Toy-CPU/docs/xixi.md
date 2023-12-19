# structure
riscv_top (ram + cpu)
# memory：
## ram:2-ports
addr_a,dout_a
addr_b,din_b,dout_b
## memctrl:in CPU
for now: one cycle per instruction, state machine(2state)

handle with if:
1. valid: 
2. done: count cycles itself, when done, set done bit (always transfer data).
handle with ls:

# cpu
## i_fetch
status 状态转移
1. IDLE(00): 空闲，可以向 mc 传一个地址
2. WAIT_MEM(01): 正在等待 mc load 结束，如果结束(done)，更改 pc。进入 WAIT_DECODE
3. WAIT_DECODE(10): 等待 idecode，vacant 时将指令送入。若为bne，进入 STALL，否则进入IDLE
3. STALL(11): 等待 offset，更改 pc 后才能继续进入 IDLE，准备取指令
## i_decode
vacant 连 vacant
对每条 inst，拆解为 op,rd,rs1,rs2,imm，传入 ib
舍弃 [14:12] 的三位 opt，只需 [6:0] 即可
sign-extend imm to 32-bit

## i_buffer
循环队列: 
1. 入队：rear++
2. 出队：front++
3. empty: rear=front; 
4. full: rear+1=front
### ib state machine
send state: WaitSend->Sent->Pop->(Empty->)WaitSend
receive state: WaitReceive->Received->(Full->)WaitReceive
### ib mark
1. sb_valid == 1: this cycle an instruction is being sent to scoreboard
2. id_valid == 1: this cycle an instruction is being received
3. id_vacant == 1: some time later an instruction will come

## scoreboard
ALU entry and LS entry，统一用 num（下标）标记
reg_file 作为两个数组内嵌其中
exe_pos: 发射的pos
alu_ready_pos: 可以发射的alu_pos
INVALID_POS:11111...，在dependency和regfile中表示无效(SB_SIZE=2^SB_SIZE_WIDTH - 1)
注意：always* 块中除了循环变量用**阻塞赋值**，其他都用**非阻塞赋值**！保证不会冲突（应该不会时延一个周期吧？）

### push（issue）
每个周期监控 ib_valid，如果有，就接受并放入一条 entry：
#### 维护 vacant
> 注意，ib中，在设置valid并send后至少两个周期不会受 vacant的影响，不会再send新的指令。因此vacant可以允许两个周期的滞后。
只需用一个 always@* 块时刻维护两个 vacant 变量即可。
可以验证，如果第 i 个周期 ib_valid=1,接受了一条指令，当个周期立即修改对应entry和front rear，那么下个周期 vacant 就会被更新，不会滞后。
#### 放入的位置
用 issue_pos 维护，用阻塞赋值。
然后直接利用 issue_pos 操作
1. 对于LS指令：直接放入 rear 即可
   对于ALU指令：在维护 vacant 时同时维护一个 alu_vacant_pos，表示搜索到的第一个 vacant_alu_entry，直接放入这里即可.(若不vacant，为INVALID_POS)
2. 放入之后：valid<=1(rear+=1)
#### 添加 dependency
利用 issue_pos 直接维护，减少重复代码
注意：无 dependency 则 dependency = 111111（size 是 2^width-1，即数组是 [0:2^width-2]
注意：如果**rs或rd等于0**，那么要么这个寄存器无用，要么代表0寄存器，都不需要任何dependency
1. 对 rs1,rs2: 
   1. pos.dependency = rs.last_write_pos （即 num 写回后才能发射（取数据））
   2. rs.last_read_pos <= pos
2. 对 rd：
   1. pos.WAW_dependency <= rd.last_write_pos （即num 写回后才能发射（再次覆盖写回）
   2. pos.WAR_dependency <= rd.last_read_pos （即 num 发射（取数据）后才能发射（写入新数据）
   1. rd.last_write_num <= rd

### 发射（exe）
#### 维护 ready:alu_ready_pos和ls_ready
一个 always@* block:
一个循环遍历所有ALU entry，检查每个 exe = 0(还未发射) 的 entry 所有dependency是否都为11111，遇到第一个这样的 entry，就设置 ALU_ready_pos = pos，并结束循环。如果没有，ALU_ready_pos = ALU_ENTRY_SIZE。
检查 ls 不空，且 front 位置的 exe == 0 且各dependency 均无, 则ls_ready = 1，否则 ls_ready = 0
#### 在每个上升沿：
1. 如果 ALU_busy = 0 && ALU_ready_pos < ALU_ENTRY_SIZE，exe_pos = alu_ready_pos，ALU_busy = 1, exe = 1。
2. 如果 ALU 发不出，如果 ls_ready 且不 busy，发射，exe_pos = ls_front, exe = 1,ls_busy = 1

#### 对所有发射：
1. 只更改 exe_pos, reg_valid,reg_dest,alu_valid,ls_valid，其他数据自动传输
1. rs1,rs2,dest 送到 register；rd,imm,op,funct,num 送到 ALU/LS。

对 exe_pos 阻塞赋值，后续统一修改 dependency
2. 若 rs1,rs2 的 last_read_pos 是 exe_pos,更改为 invalid_pos
1. 遍历所有 WAR_dependency，若为 exe_pos，消除该 WAR_dependency

### 处理写回
每个上升沿，查看 wb 是否 valid，若是，
1. 消除 ALU/LS 的 busy(根据 pos)，将 wb_pos 的 entry.valid = 0（删除），对 ls 出队
3. 对 rd 的 last_write_pos，若为 wb_pos, 更改为 invalid_pos
2. 遍历所有 rs_dependency 和 WAW_dependency，若等于 wb_pos, 消除该 dependency

### issue,exe,wb 导致的赋值冲突问题
#### Problems
1. issue 会设置 issue_pos 的 4 个dependency，和对应特定寄存器的 last_read/write_pos
2. exe 可能会消除任意 entry 的 war dependency，消除特定 reg 的 last_read_pos
3. wb 会消除任意位置的 raw,waw dependency,消除特定 reg 的 last_write_pos
显然 exe 和 wb 均不冲突，issue 与后两者都可能冲突
#### Solutions
1. 对 4 个 dependency：issue_pos 一定是在当前周期空(valid == 0) 的位置，而我们消除 dependency 时都会检查 valid，因此不会修改同一位置的 dependency
2. 对 regfile：如果新 issue 的指令与 exe 或 wb 的指令对应寄存器恰好相同，则可能冲突。
3. regfile 的解决方法：如果 issue 和 exe 修改同一寄存器的 last_read_pos，exe 只是消除依赖，issue 是添加依赖，以 issue 为准。因此在 exe 和 wb 修改 regfile 前先特判一下，如果与 issue 冲突了，就不写。

# TODO MARK BUG
## 2023.11.29
1. add memctrl(what is the addr_width in cpu(instructions)? 32!)(出cpu带宽32进ram带宽16)
2. modify ram, remove valid and done bit
3. finish riscv_top
3. FIGURE OUT how to deal with 17-bit addr and modify i_fetch
4. finish cpu.v, add ifetch and memctrl properly
5. RUN and DEBUG

## 2023.12.2
1. what does rst do??
ram clears the reg in an initial block
only used in cpu module
which module in cpu need the rst signal? for what?

## 2023.12.8
### try DEBUG IFETCH and MEMCTRL
target: 波形图看起来正常，能一直读到指令（idecode相关wire先设为1）
1. add rst to ifetch
2. fixed a typo in memctrl.v
3. ram中每个单元只有一个byte，长度为8，送出去和进来的data长度为32，4byte。addr_width是16，内存一共2^16个byte，每次读写4个byte(addr-addr+3)
### start coding!!!
1. i_decode

## 2023.12.10
### start coding:
1. 完善 i_fetch 逻辑
1. mark: <= **非阻塞赋值** 是在块结束后一起赋值（上一状态决定下一状态），而不是执行完赋值语句立刻赋值！！！
2. mark: bne 指令的 imm 第 0 位是 0.
1. i_decode 

## 2023.12.11
1. mark: 实现的指令：除 lui,auipc,jal,jalr,srai,sub,sra 外的所有
2. 重写idecode
2. inst_buffer（循环队列 小粘人虫

## 2023.12.13
1. ib 实现循环队列
2. 设计并实现 ib_sb 接口和内部

## 2023.12.14
1. DEBUG id,ib，期待行为：
   sb_vacant = 0，IB_SIZE=8: 一直读指令，往ib里放指令(正确decode，正确顺序)，直到放满 7 条，然后停住，不读指令。
   sb_vacant = 1:一直读，一直往ib送，一直从ib里送出给sb。可以一直一直读到指令(正确decode，正确order)
2. BUG: ram.v 在改变addr后一个周期才能得到正确的数据！memctrl要计数等待，不能立刻done

## 2023.12.16
2. debug:
   sb_vacant = 1:一直读，一直往ib送，一直从ib里送出给sb。可以一直一直读到指令(正确decode，正确order)
2. mark: sb_valid 的瞬间，sb必须立刻接收，否则下一周期会变
3. mark: LS_ST_POS 的 generate 方式对吗？

## 2023.12.19
1. TODO: 能不能把sb 的 push 具体操作拆分到一个always 块里？
2. 搞清楚每个地方到底用阻塞还是非阻塞赋值（全部非阻塞，会撞的地方用特判（各种dep）