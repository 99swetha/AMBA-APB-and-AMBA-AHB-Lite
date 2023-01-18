// Code your testbench here
// or browse Examples
//`define CLK @(posedge pclk)
module APB_protocol_verilog_tb;
reg pclk;
reg preset_n;

reg [1:0] add_i;  // 2'b01 = read , 2'b11 = write.

wire psel_o;
wire penable_o;
wire [31:0] paddr_o;
wire pwrite_o;
wire [31:0] pwdata_o;
reg  [31:0] prdata_i;
reg pready_i;

always begin
pclk = 1'b0;
#5;
pclk = 1'b1;
#5;
end

APB_protocol_verilog dut(pclk, preset_n, add_i,psel_o, penable_o,paddr_o, pwrite_o,pwdata_o,prdata_i, pready_i);    // APB instance

initial
begin
    $dumpfile("APB_protocol_verilog.vcd");
    $dumpvars(0,APB_protocol_verilog_tb);
    preset_n = 1'b0;
    add_i = 2'b00;
    repeat (2) @(posedge pclk);
    preset_n = 1'b1;
    repeat (2) @(posedge pclk);
    
    // Initiate a read transaction
    add_i = 2'b01;
    @(posedge pclk);
    add_i = 2'b00;
    repeat (4) @(posedge pclk);
    
    // Initiate a write transaction
    add_i = 2'b11;
    @(posedge pclk);
    add_i = 2'b00;
    repeat (4) @(posedge pclk);
    #50 $finish;
end

always@(posedge pclk or negedge preset_n)begin
if(~preset_n)
pready_i <= 1'b0;
else begin
if(psel_o && penable_o)begin
pready_i <= 1'b1;
prdata_i <= 32'h20;
end else begin
pready_i <= 1'b0;
prdata_i <= 32'hFF;
end
end
end

endmodule