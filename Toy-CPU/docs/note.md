# Verilog

## 数值表示

1. 十进制 'd
2. 十六进制 'h
3. 二进制 'b
4. 八进制 'o

> 4'b1011 指明位宽
>
>  32'h3022_c0de 下划线增强可读性
>
> counter = 'd100 / counter = 100 / counter = 32'h64
>
> -6'd15 / -15 负号写在位宽前

字符串：不包含后回车，一系列单字节ACSII字符队列

> reg [0: 14*8-1]		str  ;
>
> initial begin
>
> ​		str = "www.runoob.com";
>
> end

## 数据类型

### wire

**input output 默认为wire**

assign <wire> a = <reg> b：b变a也变

只能assign一次（组合逻辑）

### reg(register)

变量放在begin...end之内必须用reg

保持数据原有的值，直到被改写，无符号

#### integer

有符号，不用声明位宽（一般32bit）

> integer j ;
>
> for (j = 0; j <= 3; j = j + 1) begin
>
> ​		byte1[j] = data1[(j + 1) * 8 - 1 : j * 8];
>
> end

#### real

#### time

特殊的时间寄存器，保存仿真时间，一般64bit

通过调用系统函数$time获取当前仿真时间

### vector

位宽大于1时，wire或reg可声明为向量

>reg [3: 0]	counter ; 4bit的寄存器counter
>
>wire [8: 2]	addr ; 4bit的线型变量，位宽范围为8: 2
>
>wire [31: 0]	gpio_data ；32bit的线型变量gpio_data
>
>reg [0: 31]	data ; 32bit的寄存器data，最高有效位为0

可以指定某一位或若干连续位

> wire [9: 0]	data_low = data[0: 9]
>
> assign  w[3: 0] = b[0: 3]
>
> addr_temp[3: 2] = addr[8 : 7] + 1'b1 ;

支持可变的变量域选择

> for (j = 0; j <= 3; j = j + 1) begin
>
> ​		byte1[j] = data1[(j + 1) * 8 - 1 : j * 8];
>
> end

支持指定bit位后固定位宽的向量域选择访问

[bit+: width] / [bit-: width]

> A = data1[31- : 8] ; A = data1[31 : 24] ;
>
> B = data1[0+ : 8] ; B = data1[0 : 7] ;

借助大括号，对信号重新组合成新的向量

> wire[31 : 0]		temp1, temp2 ;
>
> assign temp1 = {byte1\[0\][7: 0], data1[31 : 8]} ; 数据拼接
>
> assign temp2 = {32{1'b0}} ; 赋值32位的数值0

### array（数组）

元素类型：reg, wire, integer, time, real, **vector**

> integer 	flag [7 : 0] ;
>
> reg [3 : 0]	counter [3 : 0] ; 4个4bit计数器组成的数组
>
> wire [7 : 0] 	addr_bus [3 : 0] ; 4个8bit wire组成的数组
>
> wire 	data_bit[7 : 0\][5 : 0] ;1bit wire型的二维数组

对数组元素赋值

> flag[1] = 32'd0
>
> counter[3] = 4'hF
>
> assign addr_bus[0]  = 8'b0

### 存储器：reg数组

> reg	membit[0:255]
>
> reg [7:0] 	mem[0:1023]

### parameter

常量，只能赋值一次

> parameter 	data_width = 10'd32

## 表达式——操作符

### 算术

加减乘除，取模（%）

注意结果reg位宽足够大，否则高位截断

### 关系/等价

<, >, >= , <= , == , !=

=== , !== 全等： 可比较x或z

### 逻辑

&& , || , !

### 按位

~取反，&与，|或，^异或，~^同或（异或取反）

### 归约

只有一个操作数，对其每一位逐位操作，产生1bit结果

&, ~& ,  | , ~| , ^ , ~^

>A = 4'b1010 ;
>
>&A ; 1 & 0 &1 & 0 
>
>~|A ;
>
>^A ;

### 移位

<< ，>> , <<< , >>> 

逻辑右移：高位补0；算术右移：高位符号扩展

逻辑左移=算术左移

### 拼接 {， }

将多个操作数（向量）拼接成新的操作数

操作数（包括常量）必须指定位宽

> A = 4'b1010
>
> B = 1'b1 ;
>
> Y1 = {B, A[3:2] , A[0] , 4'h3} ;
>
> Y2 = {4{B} , 3'd4} ; 4{B}表示4个B

### 条件

<expression> ? <true_expression> : <false_expression>

## module

1. 代表硬件电路上的逻辑实体
2. 每个模块实现特定功能
3. 模块间并行运行
4. 高层模块调用、连接底层模块的**实例**来实现复杂的功能
5. 各模块通过顶层模块**top-module**连接

### always块

> always @(event) begin
>
> ​	[multiple statements]
>
> end

#### (event)敏感列表

1. **(a or b) **当信号a或b发生变化时，块会被顺序执行
2. **(posedge clk)** 在每个上升沿执行always块内语句
3. 敏感列表为空：**其他形式的时间延迟** always #10 clk=~clk

#### initial 块

同一模块中可以有多个initial块，它们同时在0时刻同步进行