// UART (Universal Asynchronous Receiver/Transmitter) sends data serially, one bit at a time, 
// without a shared clock between sender and receiver — timing is inferred purely from a known, 
// agreed-upon baud rate (bits per second).

module uart_transmitter #(
    parameter int CLK_FREQ   = 50_000_000,
    parameter int BAUD_RATE  = 9600,
    parameter int DATA_WIDTH = 8
) (
    input logic clk,
    input logic rst,
    input logic tx_start,
    input logic [DATA_WIDTH-1:0] data,
    output logic tx,
    output logic tx_busy
);
  typedef enum logic [1:0] {
    IDLE  = 2'b00,
    START = 2'b01,
    DATA  = 2'b10,
    STOP  = 2'b11
  } state_t;

  localparam int CYCLES_PER_BIT = CLK_FREQ / BAUD_RATE;

  state_t current_state, next_state;

  logic [$clog2(CYCLES_PER_BIT-1):0] baud_counter;
  logic [$clog2(DATA_WIDTH-1):0] bit_counter;
  logic [DATA_WIDTH-1:0] shift_reg;


  always_ff @(posedge clk) begin
    if (rst) begin
      current_state <= IDLE;
      bit_counter   <= 0;
      baud_counter  <= 0;

    end else begin
      current_state <= next_state;

      // Baud counter
      if (current_state != next_state) baud_counter <= 0;
      else if (baud_counter == CYCLES_PER_BIT - 1)
        baud_counter <= 0;  // wrap around -> "one bit period has elapsed"
      else baud_counter <= baud_counter + 1;

      // Bit counter: only relevant on Data state, increment when baud counter equals clycles per bit
      if (current_state != DATA) bit_counter <= 0;
      else if (baud_counter == CYCLES_PER_BIT - 1) bit_counter <= bit_counter + 1;

      // Shift register: load on START->DATA, update in DATA and baud counter equals cycles per bit
      if (current_state == START && next_state == DATA) shift_reg <= data;
      else if (current_state == DATA && baud_counter == CYCLES_PER_BIT - 1)
        shift_reg <= {1'b0, shift_reg[DATA_WIDTH-1:1]};

    end
  end

  always_comb begin
    case (current_state)
      IDLE: begin
        if (tx_start) next_state = START;
        else next_state = IDLE;
        // Combinaltional outputs
        tx = 1;
        tx_busy = 0;
      end
      START: begin
        if (baud_counter == CYCLES_PER_BIT - 1) next_state = DATA;
        else next_state = START;
        // Combinaltional outputs
        tx = 0;
        tx_busy = 1;
      end
      DATA: begin
        if (bit_counter == DATA_WIDTH - 1 && baud_counter == CYCLES_PER_BIT - 1) next_state = STOP;
        else next_state = DATA;
        // Combinaltional outputs
        tx = shift_reg[0];
        tx_busy = 1;
      end
      STOP: begin
        if (baud_counter == CYCLES_PER_BIT - 1) next_state = IDLE;
        else next_state = STOP;
        // Combinaltional outputs
        tx = 1;
        tx_busy = 1;
      end
      default: begin
        next_state = IDLE;
        tx = 1;
        tx_busy = 0;
      end
    endcase

  end

endmodule
