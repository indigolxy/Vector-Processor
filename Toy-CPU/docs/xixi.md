# structure

## riscv_top (ram + cpu)
### memory
#### ram:2-ports
addr_a,dout_a
addr_b,din_b,dout_b
#### memctrl:in CPU
for now: one cycle per instruction, no need to count

handle with if:
1. valid: 
2. done: count cycles itself, when done, set done bit (always transfer data).
handle with ls:

### cpu
#### i_fetch
status 状态转移
1. IDLE(00): 空闲，可以向 mc 传一个地址
2. WAIT_MEM(01): 正在等待 mc load 结束，如果结束(done)，更改 pc。进入 WAIT_DECODE
3. WAIT_DECODE(10): 等待 idecode，vacant 时将指令送入。若为bne，进入 STALL，否则进入IDLE
3. STALL(11): 等待 offset，更改 pc 后才能继续进入 IDLE，准备取指令
#### i_decode
vacant 连 vacant
对每条 inst，拆解为 op,rd,rs1,rs2,imm，传入 ib
舍弃 [14:12] 的三位 opt，只需 [6:0] 即可
sign-extend imm to 32-bit

#### i_buffer

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
2. 详细梳理每种指令怎么跑，scoreboard 的逻辑
3. mark：scoreboard 一半队列(ls)一半不用，看看遍历怎么实现