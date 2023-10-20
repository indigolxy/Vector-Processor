[【精选】Verilog常用语法_verilog语法_电路_fpga的博客-CSDN博客](https://blog.csdn.net/weixin_50810761/article/details/113091498)

# outline

1. wire：接线，不会保存数据（没有reg结构），只传输数据。assign wire =reg
2. reg：保存数据，直到被改写。
3. module：硬件上的“模块”，并行运行。高层 module 调用底层 module 的**实例**，所有 module 由一个 top-module 调用。
4. 一个 module 的语句中只能由变量定义、实例引用、连续赋值(assgin)、过程块(always/initial)组成
5. 过程块内被赋值的所有信号都应是 reg
6. always 块：每次敏感列表发生（事件 or 上升沿or每n秒...）时执行一遍
7. initial 块：同一 module 中所有 initial 块同步在 0 时刻同时执行
8. 在 Verilog 语言中，所有的变量都是静态的，即所有的变量都只有一个唯一的存储地址，因此进入或跳出块并不影响存储在变量的值
9. for 循环：不是每一遍顺序执行。只是复制代码，要先将代码展开，再看展开后的**电路**。
10. 一个程序模块可以有多个initial和always过程块，**每个initial和always**说明语句在**仿真的一开始同时立即开始执行**，initial语句只执行一次，而always语句则不断重复活动着，直到仿真过程结束；

# Verilog 语法

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
4. @* @(*)：它们都表示对其后面语句块中所有输入变量的变化是敏感列表

### initial 块

同一模块中可以有多个initial块，它们同时在0时刻同步进行

## 赋值语句

### <= 非阻塞

在开始时计算rhs，结束时赋值给lhs，全程允许其他语句进行操作

（时序电路，两种逻辑都有的always块）

非阻塞是并行的：也就是接线上实现的，用到的值全部从**上一个状态**转移过来，读后写/写后读不存在问题，但两个写会冲突。

### = 阻塞赋值

在**同一时刻**进行rhs的计算和lhs的赋值，结束后才允许其他语句执行。

可综合的：rhs不能有延迟

e.g. 在一个过程块中阻塞赋值的RHS变量正好是另一个过程块中阻塞赋值的LSH变量，这两个过程块又用同一时钟沿触发，这时阻塞赋值操作会出现问题，即如果阻塞赋值的顺序安排不好，就会出现竞争。若这两个阻塞赋值操作用同一个时钟沿触发，则执行的顺序是无法确定的。

（always块中仅有组合逻辑时）

## task and function

* 任务和函数都是用来对设计中多处使用的公共代码进行定义，将模块分割成许多个可独立管理的子单元，增加了模块的可读性和可维护性。
* task：任意多个输入、输出，可以使用延迟、事件和时序控制结构，可以调用其它的task和function
* 可重入task/可递归function：使用关键字automatic进行定义，它的每一次调用都对不同的地址空间进行操作。因此在被多次并发调用时，它仍然可以获得正确的结果；
* function：只能有一个返回值，并且至少要有一个输入变量；不能使用延迟、事件和时序控制结构，但可以调用其它function，不能调用task。

### function

1. 返回值：在语句中必须有一条赋值语句给**与函数同名**的内部变量返回值
2. 不能包含任何的时间控制语句，即用任何用#、@或wait来标识的语句
3. 至少要有一个输入变量

### 常量函数

参数是常量的函数

> 例如：在工程中，参数化设计是非常常见的。模块接口的位宽，常见的有8位、16位、32位、64位和128位等；虽然功能相同，仅因为位宽不同，就要另外写一个模块，那设计工作就很繁复了。为此，我们可以采用参数化来实现，即用parameter来定义常数。但是参数化会遇到一个问题，就是某些信号的位宽跟此参数有着密切的关系。例如，我们可以使用parameter来定义FIFO的深度，但是表示FIFO深度的信号usedw，其位宽是跟参数相关的。如果深度为512，usedw位宽是9位，如果深度为1024，其位宽是10位。这时如果此模块可以自己计算位宽那就再好不过了。
>
> ```
> module ram(.. .. ..);
> 	parameter RAM_DEPTH = 256;
> 	input [clogb2(RAM_DEPTH)-1:0] addr_bus;
> 	..
> 	..
> 	//
> 	function integer clogb2(input integer depth)begin
> 		if(depth==0)
> 			clogb2 = 1;
> 		else if(depth!=0)
> 			for(clogb2==0;clogb2>0;clogb2=clogb2+1)
> 				depth = depth + 1;
> 	end
> 	endfunction
> endmodule
> ```

### 常用系统任务

#### 输出

```
$ display （p1,p2,……pn）;
$ write（p1,p2,……pn）；
```

将参数p2到pn按参数p1给定的格式输出。

* \$ **display**自动在输出后**换行**，\$ write则不是这样，如果想在一行里输出多个信息，可以使用$ write。
* p1 的格式：可查表，类似`printf`

#### 文件输出

1. 打开文件
   用法：`$ fopen（“<文件名>”）；`
   用法：`<文件句柄>=$ fopen（“<文件名>”）；`
2. 写文件
   系统任务 `$ fdisplay、$ fmonitor、$ fwire、$ fstrobe`都用于写文件；
   格式：`$ fdisplay（<文件描述符>，p1,p2,……,pn）；`
   格式：`$ fmonitor（<文件描述符>，p1,p2,……,pn）；`
3. 关闭文件
   用法：`$fclose（<文件描述符>）；`

### 调试用系统任务

#### $moniter

```
$monitor（p1,p2,……pn）;
$monitor;
$monitoron;
$monitoroff;
```

`monitor`：*监控和输出参数列表中的表达式或变量值。*

* 每当 moniter 参数列表中变量或表达式的**值变化**时，**整个参数列表**中的变量或表达式的值都将**输出显示**。如果**同一时刻**两个或多个参数的值发生变化时，则在该时刻输出**只显示一次**。
* 参数可以是 `$time` 系统函数

`$monitoron` 和 `$monitoroff`：*通过打开或关闭监控标志来控制监控任务 `$monitor` 的启动和停止。*

* 通常在**调用** `$ monitoron` 时，不管 `$ monitor` 参数列表中的值是否发生变化，总是**立刻输出**显示当前时刻参数列表中的值，这用于在监控的初始时刻**设定初始比较值**。
* 在默认情况下，控制标志在仿真的起始时刻就已经打开了
* 在**多模块调试**的情况下，因为**任何时刻只能有一个 `$ monitor` 起作用**，因此需配合 `$monitoron` 和 `$monitoroff`使用，在监视完毕后及时用 `$monitoroff` 关闭，以便把 `$ monitor` 让给其它模块使用。
* `$monitor` 往往在 `initial` 块中调用，只要不调用 `$monitoroff`，`$monitor` 便不间断地对所设定的信号进行监视。**不需要、也不能在always过程块中调用 `$monitor`**

#### $time

1. `$time` 返回一个64位的整数来表示当前的仿真时刻值，以模块的仿真时间尺度为基准，输出的总是时间尺度的倍数，且总是输出整数。
2. `$realtime` 和 `$time` 的作用是一样的，只是 `$realtime` 返回的数字是一个实型数，该数字也是以时间尺度位基准的。

#### $random

*返回一个32位随机数。*

`$random%b` （b>0），给出了一个在（-b+1）：（b-1）中的随机数。

```
reg[23:0] rand;
rand={$random}%60; // 通过位并接操作产生一个值在0~59之间的数
```

#### $finish

```
$finish；
$finish（n）;
```

退出仿真器，返回主操作系统。如果不带参数，默认$finish的参数值为1。

参数的含义：

* 0 不输出任何信息；

* 1 输出当前仿真时刻和位置；

* 2 输出当前仿真时刻、位置和在仿真过程中所用的memory及cpu时间统计。

#### $stop

```
$stop；
$stop（n）;
```

把EDA工具（例如仿真器）置成暂停模式，在仿真环境下给出一个交互式的命令提示符，将控制权交给用户·。根据参数值的不同，输出不同的信息，参数越大，输出的信息越多。

### 编译预处理

1. ``include `

2. ``timescale` 时间尺度 

   ``timescale时间单位/时间精度` **时间单位**：定义模块中仿真时间和延迟时间的**基准单位**，**时间精度**：声明该模块的仿真时间**精确程度**的。

   * 时间精度不能大于时间单位值。
   * 如果在同一个程序设计中，存在多个``timescale`命令，则用**最小的时间精度值**来决定仿真的**时间单位**
   * 时间单位和时间精度必须是**整数**；
   * 当多个带不同 ``timescale` 定义的模块包含在一起时只有最后一个起作用。

3. `ifdef、else、endif`