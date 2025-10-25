module matrix_mult_simple_mem (
    input clk,
    input reset,
    input start,
    output reg done
);
    reg [7:0] mem_A [0:15];
    reg [7:0] mem_B [0:15];
    reg [15:0] mem_C [0:15];

    integer i, j, k;
    reg [15:0] sum;
    reg [3:0] addr_A, addr_B, addr_C;

    reg [1:0] state;
    parameter IDLE = 2'b00, CALC = 2'b01, DONE = 2'b10;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            done <= 0;
            i <= 0;
            j <= 0;
            k <= 0;
        end else begin
            case(state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        mem_A[0]=1; mem_A[1]=2; mem_A[2]=3; mem_A[3]=4;
                        mem_A[4]=5; mem_A[5]=6; mem_A[6]=7; mem_A[7]=8;
                        mem_A[8]=9; mem_A[9]=10;mem_A[10]=11;mem_A[11]=12;
                        mem_A[12]=13;mem_A[13]=14;mem_A[14]=15;mem_A[15]=16;

                        mem_B[0]=1; mem_B[1]=0; mem_B[2]=0; mem_B[3]=0;
                        mem_B[4]=0; mem_B[5]=1; mem_B[6]=0; mem_B[7]=0;
                        mem_B[8]=0; mem_B[9]=0; mem_B[10]=1; mem_B[11]=0;
                        mem_B[12]=0; mem_B[13]=0; mem_B[14]=0; mem_B[15]=1;

                        i <= 0; j <= 0; k <= 0;
                        sum <= 0;
                        state <= CALC;
                    end
                end

                CALC: begin
                    if (i < 4) begin
                        if (j < 4) begin
                            if (k < 4) begin
                                addr_A = i*4 + k;
                                addr_B = k*4 + j;
                                sum = sum + mem_A[addr_A] * mem_B[addr_B];
                                k = k + 1;
                            end else begin
                                addr_C = i*4 + j;
                                mem_C[addr_C] = sum;
                                sum = 0;
                                k = 0;
                                j = j + 1;
                            end
                        end else begin
                            j = 0;
                            i = i + 1;
                        end
                    end else begin
                        state <= DONE;
                    end
                end

                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
