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

# TODO
## 2023.11.29
1. add memctrl(what is the addr_width in cpu(instructions)? 32!)(出cpu带宽32进ram带宽16)
2. modify ram, remove valid and done bit
3. finish riscv_top
3. FIGURE OUT how to deal with 17-bit addr and modify i_fetch
4. finish cpu.v, add ifetch and memctrl properly
5. RUN and DEBUG

