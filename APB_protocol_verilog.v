module APB_protocol_verilog(pclk, preset_n, add_i,psel_o, penable_o,paddr_o, pwrite_o,pwdata_o,prdata_i, pready_i);
  input pclk;
  input preset_n;
  input [1:0] add_i;  // 2'b01 = read , 2'b11 = write.
  output psel_o;
  output penable_o;
  output [31:0] paddr_o;
  output pwrite_o;
  output [31:0] pwdata_o;
  input [31:0] prdata_i;
  input pready_i;

  parameter ST_IDLE=2'b00, ST_SETUP=2'b01, ST_ACCESS=2'b10;

  reg [1:0] curr_q;
  reg [1:0] nxt_state;

  reg nxt_pwrite;
  reg pwrite_q;

  reg [31:0] nxt_prdata;
  reg [31:0] prdata_q;

  always@(posedge pclk or negedge preset_n)
    if(~preset_n)
      curr_q <= ST_IDLE;
    else
      curr_q <= nxt_state;

  always@(*)
  begin
    nxt_pwrite = pwrite_q;                          //
    nxt_prdata = prdata_q;
    case(curr_q)
      ST_IDLE:
        if(add_i[0])
        begin
          nxt_state = ST_SETUP;
          nxt_pwrite = add_i[1];                 //
        end
        else
          nxt_state = ST_IDLE;
      ST_SETUP:
        nxt_state = ST_ACCESS;
      ST_ACCESS:
        if(pready_i)
        begin
          nxt_state = ST_IDLE;
        if(~pwrite_o)begin
          nxt_prdata = prdata_i;
        end
        end
        else
          nxt_state = ST_ACCESS;
      default:
        nxt_state = ST_IDLE;
    endcase
  end

  assign psel_o = (curr_q == ST_SETUP) | (curr_q == ST_ACCESS);
  assign penable_o = (curr_q == ST_ACCESS);


  //APB Address
  assign paddr_o = {32{curr_q == ST_ACCESS}} & 32'hA000;


  //APB PWRITE control signal
  always@(posedge pclk or negedge preset_n)
    if(~preset_n)
      pwrite_q <= 1'b0;
    else
      pwrite_q <= nxt_pwrite;

  assign pwrite_o = pwrite_q;

  //APB PWDATA data signal
  assign pwdata_o = {32{curr_q == ST_ACCESS}} & (prdata_q + 32'h1);

  always@(posedge pclk or negedge preset_n)
  begin
    if(~preset_n)
      prdata_q <= 32'h0;                                     //
    else
      prdata_q <= nxt_prdata;                                //

  end

endmodule








