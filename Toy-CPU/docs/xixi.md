# structure

## riscv_top
ram + cpu

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

# TODO and MARK and BUG
## 2023.11.29
1. add memctrl(what is the addr_width in cpu(instructions)? 32!)(出cpu带宽32进ram带宽16)
2. modify ram, remove valid and done bit
3. finish riscv_top
3. FIGURE OUT how to deal with 17-bit addr and modify i_fetch
4. finish cpu.v, add ifetch and memctrl properly
5. RUN and DEBUG

## 2023.12.2
1. what does rst do??
ram clears the reg in an initial block,
so rst is only used in cpu module.
then what module in cpu need the rst signal? for what?

## 2023.12.8
### try DEBUG IFETCH and MEMCTRL
target: 波形图看起来正常，能一直读到指令（idecode相关wire先设为1）
1. add rst to ifetch
2. fixed a typo in memctrl.v
3. ram中每个单元只有一个byte，长度为8，送出去和进来的data长度为32，4byte。addr_width是16，内存一共2^16个byte，每次读写4个byte(addr-addr+3)
