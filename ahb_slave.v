module ahb_slave(
    input hclk,
    input hresetn,
    input hsel,
    input [31:0] haddr,
    input hwrite,
    input [2:0] hsize,
    input [2:0] hburst,
    input [3:0] hprot,
    input [1:0] htrans,
    input hmastlock,
    input hready,
    input [31:0] hwdata,
    output reg hreadyout,
    output reg hresp,
    output reg [31:0] hrdata
  );

  reg [31:0] mem [31:0]; // memory
  reg [4:0] waddr;
  reg [4:0] raddr;

  reg [1:0] state; // current state
  reg [1:0] next_state;
  localparam idle = 2'b00,s1 = 2'b01,s2 = 2'b10,s3 = 2'b11;

  reg single_flag;
  reg incr_flag; // undefined length increment transfer
  reg wrap4_flag;
  reg incr4_flag;
  reg wrap8_flag;
  reg incr8_flag;
  reg wrap16_flag;
  reg incr16_flag;

  always @(posedge hclk, negedge hresetn)
  begin
    if(!hresetn)
    begin // asynchronous, active low reset
      state <= idle;
    end
    else
    begin
      state <= next_state;
    end
  end

  always @(*)
  begin
    case(state)
      idle:
      begin
        single_flag = 1'b0; // all signals to zero
        incr_flag = 1'b0;
        wrap4_flag = 1'b0;
        incr4_flag = 1'b0;
        wrap8_flag = 1'b0;
        incr8_flag = 1'b0;
        wrap16_flag = 1'b0;
        incr16_flag = 1'b0;
        if(hsel == 1'b1)
        begin
          next_state = s1;
        end
        else
        begin
          next_state = idle;
        end
      end
      s1:
      begin
        case(hburst)
          // single transfer burst
          3'b000:
          begin
            single_flag = 1'b1;
            incr_flag = 1'b0; // assigning rest signals zero. To avoid signal corruption.
            wrap4_flag = 1'b0;
            incr4_flag = 1'b0;
            wrap8_flag = 1'b0;
            incr8_flag = 1'b0;
            wrap16_flag = 1'b0;
            incr16_flag = 1'b0;
          end
          // incrementing burst of undefined length
          3'b001:
          begin
            single_flag = 1'b0;
            incr_flag = 1'b1;
            wrap4_flag = 1'b0;
            incr4_flag = 1'b0;
            wrap8_flag = 1'b0;
            incr8_flag = 1'b0;
            wrap16_flag = 1'b0;
            incr16_flag = 1'b0;
          end
          // 4-beat wrapping burst
          3'b010:
          begin
            single_flag = 1'b0;
            incr_flag = 1'b0;
            wrap4_flag = 1'b1;
            incr4_flag = 1'b0;
            wrap8_flag = 1'b0;
            incr8_flag = 1'b0;
            wrap16_flag = 1'b0;
            incr16_flag = 1'b0;
          end
          // 4-beat incrementing burst
          3'b011:
          begin
            single_flag = 1'b0;
            incr_flag = 1'b0;
            wrap4_flag = 1'b0;
            incr4_flag = 1'b1;
            wrap8_flag = 1'b0;
            incr8_flag = 1'b0;
            wrap16_flag = 1'b0;
            incr16_flag = 1'b0;
          end
          // 8-beat wrapping burst
          3'b100:
          begin
            single_flag = 1'b0;
            incr_flag = 1'b0;
            wrap4_flag = 1'b0;
            incr4_flag = 1'b0;
            wrap8_flag = 1'b1;
            incr8_flag = 1'b0;
            wrap16_flag = 1'b0;
            incr16_flag = 1'b0;
          end
          // 8-beat incrementing burst
          3'b101:
          begin
            single_flag = 1'b0;
            incr_flag = 1'b0;
            wrap4_flag = 1'b0;
            incr4_flag = 1'b0;
            wrap8_flag = 1'b0;
            incr8_flag = 1'b1;
            wrap16_flag = 1'b0;
            incr16_flag = 1'b0;
          end
          // 16-beat wrapping burst
          3'b110:
          begin
            single_flag = 1'b0;
            incr_flag = 1'b0;
            wrap4_flag = 1'b0;
            incr4_flag = 1'b0;
            wrap8_flag = 1'b0;
            incr8_flag = 1'b0;
            wrap16_flag = 1'b1;
            incr16_flag = 1'b0;
          end
          // 16-beat incrementing burst
          3'b111:
          begin
            single_flag = 1'b0;
            incr_flag = 1'b0;
            wrap4_flag = 1'b0;
            incr4_flag = 1'b0;
            wrap8_flag = 1'b0;
            incr8_flag = 1'b0;
            wrap16_flag = 1'b0;
            incr16_flag = 1'b1;
          end
          // default
          default:
          begin
            single_flag = 1'b0;
            incr_flag = 1'b0;
            wrap4_flag = 1'b0;
            incr4_flag = 1'b0;
            wrap8_flag = 1'b0;
            incr8_flag = 1'b0;
            wrap16_flag = 1'b0;
            incr16_flag = 1'b0;
          end
        endcase


        if((hwrite == 1'b1) && (hready == 1'b1))
        begin
          next_state = s2; // write operation
        end
        else if((hwrite == 1'b0) && (hready == 1'b1))
        begin
          next_state = s3; // read operation
        end
        else
        begin
          next_state = s1; // remain in same state
        end
      end
      s2:
      begin // write operation
        case(hburst)
          // single transfer burst
          3'b000:
          begin
            if(hsel == 1'b1)
            begin
              next_state = s1;
            end
            else
            begin
              next_state = idle;
            end
          end
          // incrementing burst of undefined length
          3'b001:
          begin
            next_state = s2;
          end
          // 4-beat wrapping burst
          3'b010:
          begin
            next_state = s2;
          end
          // 4-beat incrementing burst
          3'b011:
          begin
            next_state = s2;
          end
          // 8-beat wrapping burst
          3'b100:
          begin
            next_state = s2;
          end
          // 8-beat incrementing burst
          3'b101:
          begin
            next_state = s2;
          end
          // 16-beat wrapping burst
          3'b110:
          begin
            next_state = s2;
          end
          // 16-beat incrementing burst
          3'b111:
          begin
            next_state = s2;
          end
          // default
          default:
          begin
            if(hsel == 1'b1)
            begin
              next_state = s1;
            end
            else
            begin
              next_state = idle;
            end
          end
        endcase
      end
      s3:
      begin // read operation
        case(hburst)
          // single transfer burst
          3'b000:
          begin
            if(hsel == 1'b1)
            begin
              next_state = s1;
            end
            else
            begin
              next_state = idle;
            end
          end
          // incrementing burst of undefined length
          3'b001:
          begin
            next_state = s3;
          end
          // 4-beat wrapping burst
          3'b010:
          begin
            next_state = s3;
          end
          // 4-beat incrementing burst
          3'b011:
          begin
            next_state = s3;
          end
          // 8-beat wrapping burst
          3'b100:
          begin
            next_state = s3;
          end
          // 8-beat incrementing burst
          3'b101:
          begin
            next_state = s3;
          end
          // 16-beat wrapping burst
          3'b110:
          begin
            next_state = s3;
          end
          // 16-beat incrementing burst
          3'b111:
          begin
            next_state = s3;
          end
          // default
          default:
          begin
            if(hsel == 1'b1)
            begin
              next_state = s1;
            end
            else
            begin
              next_state = idle;
            end
          end
        endcase
      end
      default:
      begin
        next_state = idle;
      end
    endcase
  end

  always @(posedge hclk, negedge hresetn)
  begin
    if(!hresetn)
    begin
      hreadyout <= 1'b0;
      hresp <= 1'b0;
      hrdata <= 32'h0000_0000;
      waddr <= 5'b0000_0;
      raddr <= 5'b0000_0;
    end
    else
    begin
      case(next_state)
        idle:
        begin
          hreadyout <= 1'b0;
          hresp <= 1'b0;
          hrdata <= hrdata; // previous values assignment
          waddr <= waddr;
          raddr <= raddr;
        end
        s1:
        begin
          hreadyout <= 1'b0;
          hresp <= 1'b0;
          hrdata <= hrdata;
          waddr <= haddr;
          raddr <= haddr;
        end
        s2:
        begin // write operation
          case({single_flag,incr_flag,wrap4_flag,incr4_flag,wrap8_flag,incr8_flag,wrap16_flag,incr16_flag})
            // single transfer
            8'b1000_0000:
            begin
              hreadyout <= 1'b1;
              hresp <= 1'b0; // Okay response
              mem[waddr] <= hwdata;
            end
            // increment of undefined length  HBURST
            8'b0100_0000:
            begin
              hreadyout <= 1'b1;
              hresp <= 1'b0;
              mem[waddr] <= hwdata;
              waddr <= waddr + 1'b1; // incremental transfer
            end
            // HBURUST=wrap 4 // four beats. HSIZE=byte  [transfer]
            8'b0010_0000:
            begin
              hreadyout <= 1'b1;
              hresp <= 1'b0;
              if(waddr < (haddr + 2'd3))
              begin
                mem[waddr] <= hwdata;
                waddr <= waddr + 1'b1; // should have used hsize. waddr <= waddr + hsize
              end
              /*
              if(waddr < (waddr + 2'd3)) begin
                mem[waddr] <= hwdata;
                waddr <= waddr + 1'b1; // should have used hsize. waddr <= waddr + hsize
                haddr <= haddr + 2'd3;
              end 
              */
              else
              begin
                waddr <= haddr;       // performing the wrap
                mem[waddr] <= hwdata; // for wrap of where wrap = [haddr + 2'd3].
                
              end
            end
            // incre 4
            8'b0001_0000:
            begin
              hreadyout <= 1'b1;
              hresp <= 1'b0;
              mem[waddr] <= hwdata;
              waddr <= waddr + 1'b1;
            end
            // wrap 8
            8'b0000_1000:
            begin
              hreadyout <= 1'b1;
              hresp <= 1'b0;
              if(waddr < (haddr + 3'd7))
              begin
                mem[waddr] <= hwdata;
                waddr <= waddr + 1'b1;
              end
              else
              begin
                waddr <= haddr; // wrapping
                mem[waddr] <= hwdata;
                
              end
            end
            // incre 8
            8'b0000_0100:
            begin
              hreadyout <= 1'b1;
              hresp <= 1'b0;
              mem[waddr] <= hwdata;
              waddr <= waddr + 1'b1;
            end
            // wrap 16
            8'b0000_0010:
            begin
              hreadyout <= 1'b1;
              hresp <= 1'b0;
              if(waddr < (haddr + 4'd15))
              begin
                mem[waddr] <= hwdata;
                waddr <= waddr + 1'b1;
              end
              else
              begin
                waddr <= haddr; // wrapping
                mem[waddr] <= hwdata;
                
              end
            end
            // incre 16
            8'b0000_0001:
            begin
              hreadyout <= 1'b1;
              hresp <= 1'b0;
              mem[waddr] <= hwdata;
              waddr <= waddr + 1'b1;
            end
            // default
            default:
            begin
              hreadyout <= 1'b1;
              hresp <= 1'b0;
            end
          endcase
        end
        s3: 
        begin
          // READ OPERATION
            
          case({single_flag,incr_flag,wrap4_flag,incr4_flag,wrap8_flag,incr8_flag,wrap16_flag,incr16_flag})
            // single transfer
            8'b1000_0000: begin
              hreadyout <= 1'b1;
              hresp <= 1'b0;
              hrdata <= mem[raddr];
            end
            // incre
            8'b0100_0000:
            begin
              hreadyout <= 1'b1;
              hresp <= 1'b0;
              hrdata <= mem[raddr];
              raddr <= raddr + 1'b1;
            end
            // wrap 4
            8'b0010_0000:
            begin
              hreadyout <= 1'b1;
              hresp <= 1'b0;
              if(raddr < (haddr + 2'd3))
              begin
                hrdata <= mem[raddr];
                raddr <= raddr + 1'b1;
              end
              else
              begin
                raddr <= haddr;
                hrdata <= mem[raddr];
                
              end
            end
            // incre 4
            8'b0001_0000:
            begin
              hreadyout <= 1'b1;
              hresp <= 1'b0;
              hrdata <= mem[raddr];
              raddr <= raddr + 1'b1;
            end
            // wrap 8
            8'b0000_1000:
            begin
              hreadyout <= 1'b1;
              hresp <= 1'b0;
              if(raddr < (haddr + 3'd7))
              begin
                hrdata <= mem[raddr];
                raddr <= raddr + 1'b1;
              end
              else
              begin
                raddr <= haddr;
                hrdata <= mem[raddr];
                
              end
            end
            // incre 8
            8'b0000_0100:
            begin
              hreadyout <= 1'b1;
              hresp <= 1'b0;
              hrdata <= mem[raddr];
              raddr <= raddr + 1'b1;
            end
            // wrap 16
            8'b0000_0010:
            begin
              hreadyout <= 1'b1;
              hresp <= 1'b0;
              if(raddr < (haddr + 4'd15))
              begin
                hrdata <= mem[raddr];
                raddr <= raddr + 1'b1;
              end
              else
              begin
                raddr <= haddr;
                hrdata <= mem[raddr];
                
              end
            end
            // incre 16
            8'b0000_0001:
            begin
              hreadyout <= 1'b1;
              hresp <= 1'b0;
              hrdata <= mem[raddr];
              raddr <= raddr + 1'b1;
            end
            // default
            default:
            begin
              hreadyout <= 1'b1;
              hresp <= 1'b0;
            end
          endcase
        end
        default:
        begin
          hreadyout <= 1'b0;
          hresp <= 1'b0;
          hrdata <= hrdata;
          waddr <= waddr;
          raddr <= raddr;
        end
      endcase
    end
  end


endmodule
