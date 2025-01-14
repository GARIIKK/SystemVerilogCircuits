module spi_slave #(
    parameter int DATA_WIDTH = 8  // Default data width
)(
    input  logic                   clk,        // System clock
    input  logic                   reset_n,    // Active-low reset
    input  logic                   MOSI,       // Master Out Slave In
    input  logic                   SCK,        // SPI clock from master
    input  logic                   start,      // Start signal for reception
    output logic [DATA_WIDTH-1:0]  data_out,   // Received data
    output logic                   done        // Reception complete indicator
);
    // Internal signals
    // I propose to add "_ff", "_s", or "_reg" for all register in design. It also give better understanding of code.
    //You immideately can understand is it register or comb logic
    logic [DATA_WIDTH-1:0]         shift_reg;        // Shift register for assembling data
    logic [$clog2(DATA_WIDTH)-1:0] bit_cnt;          // Bit counter (adjusted size)
    logic                         SCK_r, SCK_rising_edge; // Registered SCK and rising edge detection
    logic                         receiving;         // Reception in progress flag

/*
    In general this module will not work
    Because here we have clock domain crossing situation
    You are using SCK (External clock) like a data which is not synch for clk
    Such situation 100% will lead for metastability and X propagation into design. Its really critical thing
    What you could do insted: just insert here double flops
    logic [1:0] sck_ff;
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sck_ff <= '0;
        end else begin
            sck_ff <= SCK;
        end
    end

    AND then use sck_ff[1] as already synched data.
*/
    // Detect rising edge of SCK
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            SCK_r <= 1'b0;
        end else begin
            SCK_r <= SCK;
        end
    end
    assign SCK_rising_edge = ~SCK_r & SCK;

    // SPI reception logic
    //Same as I described for SPI_MASTER
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            shift_reg <= '0;
            bit_cnt   <= '0;
            data_out  <= '0;
            done      <= 1'b0;
            receiving <= 1'b0;
        end else begin
            if (start && !receiving) begin
                // Initiate reception
                receiving <= 1'b1;
                bit_cnt   <= DATA_WIDTH[$clog2(DATA_WIDTH)-1:0] - 1;
                done      <= 1'b0;
            end else if (receiving) begin
                if (SCK_rising_edge) begin
                    // Sample MOSI on rising edge of SCK
                    shift_reg[bit_cnt] <= MOSI;
                    if (bit_cnt == 0) begin
                        // Reception complete
                        data_out  <= shift_reg;
                        done      <= 1'b1;
                        receiving <= 1'b0;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end
            end else begin
                done <= 1'b0;
            end
        end
    end
endmodule
/*
In general it looks really cool. What I propose to add: _i, _o for inputs and outputs respectivelly.
With such approach it much more easier to instantiate module in the top design/wrapper. Also easier to analyze internal functionality.

Small hint - name of module should be fully equal for name of file. Because when complete design is compiling by script we receive Errors for unconsistency
*/