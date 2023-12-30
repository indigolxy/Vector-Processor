# configurations
## 常量设定
### 全局常量
1. XLEN=32：指令的长度，标量寄存器的长度，一个 word 的长度
2. VLEN=512：向量寄存器的长度
<!-- 3. ELEN=32：SEW 的上限(=max{XLEN,FLEN}) -->
### 局部常量
REG_WIDTH=6, OPT_WIDTH=7, FUNCT_WIDTH=3
**REG_WIDTH** 最高位标识是向量还是标量，标量为0，向量为1
## vector 中的 CSRs
不存放在 register 中，单开一个 CSR，alu 有读写权限，ls 有读权限
### vl
要通过向量指令更新的元素数量
vl<=VLMAX=VLEN/SEW
### vtype
SEW：standard element width 表示几个 bit 是一个向量元素 
vtype[4:2]=vsew[2:0], SEW=8*2^vsew
本实现中：vtype直接存放SEW

# vector instructions
## vsetvli
> vsetvli rd, rs1, imm
> 0, [30:20]=imm[10:0]=vtype[10:0], [19:15]=rs1, 111, [11:7]=rd, 1010111
1. set SEW = 8 * 2^vtype[4:2] = 8 * 2^imm[4:2]
2. set vl = min(VLEN/SEW, rs1)
3. WB: rd = vl
（ta，ma 不管）
## unit-stride vector load/store
> vld vd, rs1
> [31:20]unimportant, [19:15]=rs1, [14:12]unimportant, [11:7]=vd, 0000111
从 rs1 开始，读 vl 个大小为 SEW 的元素（共 vl*SEW 个 byte）放入 vd（地址增加）
> vst vs2, rs1
> [31:20]unimportant, [19:15]=rs1, [14:12]unimportant, [11:7]=vs2, 0100111
从 rs1 开始，把 vs2 中 vl 个元素依序放入内存（地址增加）
注意：
1. 一个 vector 中，**低位到高位元素编号增加**，ld/st 时也是先低位再高位（随着地址增加）
2. 元素间访存顺序无规定，均可
3. 指令中的EEW一般都=SEW，EMUL=LMUL（即目标操作数和源操作数元素宽度相同），因此直接取 SEW
## integer add instructions
### add and subtract(single width)
vadd.vv, vadd.vx, vadd.vi
vsub.vv vsub.vx
vrsub.vx vrsub.vi
> vadd.vv vd, vs2, vs1
> vadd.vx vd, vs2, rs1
> vadd.vi vd, vs2, imm
> [31:26]=funct6=0(vadd), 25(vm), [24:20]=vs2, [19:15]=vs1/rs1/imm[4:0], [14:12]=funct3, [11:7]=vd, 1010111
funct3: 000 vv; 100 vx; 011 vi
vv: vd[i]= vs1[i]+vs2[i]
vx: vd[i]= rs1(SEW bits)+vs2[i]
vi: vd[i]= sext(imm)(to SEW bits)+vs2[i]
### bitwise logical inst
vand.vv vand.vx vand.vi
vor.vv vor.vx vor.vi
vxor.vv vxor.vx vxor.vi
### min/max
vminu.vv vminu.vx
vmin.vv vmin.vx
vmaxu.vv vmaxu.vx
vmax.vv vmax.vx
### single width shift
vsll.vv vsll.vx vsll.vi
vsrl.vv vsrl.vx vsrl.vi
vsra.vv vsra.vx vsra.vi
(v是被shift的数，v/x/i是偏移量)
偏移量如果超过了SEW，就认为是SEW

### 指令格式
funct6: 000000 vadd; 000010 vsub; 000011 vrsub;
      000100 vminu; 000101 vmin; 000110 vmaxu; 000111 vmax;
      001001 vand; 001010 vor;  001100 vxor;
      100101 vsll;
      101000 vsrl;
      101001 vsra;
funct3: 000 vv; 100 vx; 011 vi

# 架构
## ram
一个周期只读一个byte

## mem_ctrl
### ports
增加 len 接口，表示读/写几个 byte。
ls_data 长度变为 VLEN（可能读写向量）
### implementation
IDLE->BUSY->IDLE

## i-fetch
主体完全不变，只变接口

## i-decode
对新的向量指令解析，对所有 reg 增加一位(首位)，表示标量(0)/向量(1)

## i-buffer
reg_WID 改为 6

## scoreboard 及 exe 阶段的连线处理
从 sb 发出后，全部经过 register，用 一个周期取到数据后，再转发给对应执行单元

sb 内部；regFile 新增向量寄存器对应的依赖（32个）

## Register
32 个 scalar 和 32 个 vector
- 取数据：对 rs1，rs2 最高位处理，获取数据，若为 scalar，前面补 0。输出均为 VLEN
- 发送：根据 dest 不同，赋值给两个执行模块之一
- 其他输入：同样依据 dest，直接赋值出去
=> 在收到ib的下一个周期，把数据和指令全部发出去
  在收到wb的下个周期完成写回

## alu
分为 scalar 和 vector 两个部分

用组合逻辑维护：jump, scalar_op1, scalar_op2, scalar_res（仅对基础指令）
同时用组合逻辑维护 XLEN 长度的 VLMAX 个 vector_op1, vector_op2, vector_res

需要注意的是vector部分，将value转换为vector_op时要根据sew进行切割，切割取的是 [i*sew+XLEN-1:i*sew] 部分，再通过和一个mask进行按位与/按位或实现sign-extend。sign-extend 以后可以保证所有算术操作的正确性

在收到指令的当个周期，立刻判断指令类型，若为scalar/vector-arith，非阻塞赋值正常写入wb，即执行只需要一个周期。若为setvl，修改CSR，wb只需pos即可


# todo
1. 添加更多计算指令如 sub 等
1. 处理 LMUL
1. 支持EEW != SEW 的 ld/st
2. 支持stride ld/st

# debug
1. 在register里，alu_pos<=exe_pos，明明exe_pos是0->f，且赋值发生的上升沿是1，为什么下个上升沿alu_pos=f?