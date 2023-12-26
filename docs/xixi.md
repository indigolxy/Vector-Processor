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

# vector instructions
## vsetvli
> vsetvli rd, rs1, imm
> 0, [30:20]=imm[10:0]=vtype[10:0], [19:15]=rs1, 111, [11:7]=rd, 1010111
1. WB: set vtype[10:0] = imm[10:0] (其实只会 set SEW)
2. WB & EXE: vl = min(VLEN/SEW, rs1)
3. WB: rd = vl
## unit-stride vector load/store
> vld vd, rs1
> [31:20]unimportant, [19:15]=rs1, [14:12]unimportant, [11:7]=vd, 0000111
从 rs1 开始，读 vl 个大小为 SEW 的元素（共 vl*SEW 个 byte）放入 vd（地址增加）
> vst vs2, rs1
> [31:20]unimportant, [19:15]=rs1, [14:12]unimportant, [11:7]=vs2, 0100111
从 rs1 开始，把 vs3 中 vl 个元素依序放入内存（地址增加）
## integer add instructions
vadd.vv, vadd.vx, vadd.vi
> vadd.vv vd, vs2, vs1
> vadd.vx vd, vs2, rs1
> vadd.vi vd, vs2, imm
> [31:26]=funct6=0(vadd), 25(vm), [24:20]=vs2, [19:15]=vs1/rs1/imm[4:0], [14:12]=funct3, [11:7]=vd, 1010111
funct3: 000 vv; 100 vx; 011 vi
vv: vd[i]= vs1[i]+vs2[i]
vx: vd[i]= rs1(SEW bits)+vs2[i]
vi: vd[i]= sext(imm)(to SEW bits)+vs2[i]

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
