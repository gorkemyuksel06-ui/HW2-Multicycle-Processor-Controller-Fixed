module top(
    input  logic        clk, reset,
    output logic [31:0] WriteData, DataAdr,
    output logic        MemWrite
);
    logic [31:0] readdata;
    logic [31:0] result;

    riscv riscv(
        .clk      (clk),
        .reset    (reset),
        .adr      (DataAdr),
        .writedata(WriteData),
        .readdata (readdata),
        .memwrite (MemWrite),
        .result   (result)
    );

    memory mem(
        .clk      (clk),
        .we       (MemWrite),
        .a        (DataAdr),
        .wd       (WriteData),
        .rd       (readdata)
    );

endmodule

module memory(
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] a,
    input  logic [31:0] wd,
    output logic [31:0] rd
);
    logic [31:0] RAM [63:0];   // 64 kelime = 256 byte

    initial $readmemh("memfile.txt", RAM);

    assign rd = RAM[a[31:2]];  // word-aligned (2 LSB atlanır)

    always_ff @(posedge clk)
        if (we) RAM[a[31:2]] <= wd;

endmodule
