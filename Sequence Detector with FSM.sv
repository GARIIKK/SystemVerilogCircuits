module sequence_detector (
    input  logic clk, rst, in,    // Clock, reset, and single-bit input
    output logic detected           // Output high when sequence is detected
);
    // State encoding
    typedef enum logic [2:0] {
        S0, // Initial state
        S1, // Detected '1'
        S2, // Detected '10'
        S3, // Detected '101'
        S4  // Detected '1011'
    } state_t;

    //Good approach of using typedef, especially with this feature of auto counting/definition of states

    // I propose to add "_ff", "_s", or "_reg" for all register in design. It also give better understanding of code.
    //You immideately can understand is it register or comb logic
    state_t current_state, next_state;

    // State transition
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= S0;
        else
            current_state <= next_state;
    end

    //Good approach for FSM comb and seq part split

    // Next state logic
    always_comb begin
        case (current_state)
            S0: next_state = (in) ? S1 : S0;
            S1: next_state = (in) ? S1 : S2;
            S2: next_state = (in) ? S3 : S0;
            S3: next_state = (in) ? S4 : S2;
            S4: next_state = (in) ? S1 : S2;
            default: next_state = S0;
        endcase
    end

    // Output logic
    always_comb begin
        detected = (current_state == S4);
    end
    // Here we can even use ASSIGN construction instead of always_comb
endmodule
/*
In general it looks really cool. What I propose to add: _i, _o for inputs and outputs respectivelly.
With such approach it much more easier to instantiate module in the top design/wrapper. Also easier to analyze internal functionality.

Small hint - name of module should be fully equal for name of file. Because when complete design is compiling by script we receive Errors for unconsistency
*/