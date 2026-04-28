module riscv(
    input  logic        clk, reset,
    output logic [31:0] adr, writedata,
    input  logic [31:0] readdata,
    output logic        memwrite,
    output logic [31:0] result
);

    // Controller → Datapath signals
    logic [1:0] immsrc;
    logic [1:0] alusrca, alusrcb;
    logic [1:0] resultsrc;
    logic       adrsrc;
    logic [2:0] alucontrol;
    logic       irwrite, pcwrite;
    logic       regwrite;

    // Datapath → Controller signals
    logic [6:0] op;
    logic [2:0] funct3;
    logic       funct7b5;
    logic       zero;

    controller c(
        .clk       (clk),
        .reset     (reset),
        .op        (op),
        .funct3    (funct3),
        .funct7b5  (funct7b5),
        .zero      (zero),
        .immsrc    (immsrc),
        .alusrca   (alusrca),
        .alusrcb   (alusrcb),
        .resultsrc (resultsrc),
        .adrsrc    (adrsrc),
        .alucontrol(alucontrol),
        .irwrite   (irwrite),
        .pcwrite   (pcwrite),
        .regwrite  (regwrite),
        .memwrite  (memwrite)
    );

    datapath dp(
        .clk       (clk),
        .reset     (reset),
        .pcwrite   (pcwrite),
        .adrsrc    (adrsrc),
        .irwrite   (irwrite),
        .regwrite  (regwrite),
        .resultsrc (resultsrc),
        .alusrca   (alusrca),
        .alusrcb   (alusrcb),
        .immsrc    (immsrc),
        .alucontrol(alucontrol),
        .op        (op),
        .funct3    (funct3),
        .funct7b5  (funct7b5),
        .zero      (zero),
        .adr       (adr),
        .writedata (writedata),
        .readdata  (readdata),
        .result    (result)
    );

endmodule
