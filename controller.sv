module controller(
    input  logic        clk,
    input  logic        reset,
    input  logic [6:0]  op,
    input  logic [2:0]  funct3,
    input  logic        funct7b5,
    input  logic        zero,
    output logic [1:0]  immsrc,
    output logic [1:0]  alusrca, alusrcb,
    output logic [1:0]  resultsrc,
    output logic        adrsrc,
    output logic [2:0]  alucontrol,
    output logic        irwrite, pcwrite,
    output logic        regwrite, memwrite
);

    logic [1:0] aluop;
    logic       branch, pcupdate;

    // PCWrite = PCUpdate OR (Branch AND Zero)
    assign pcwrite = pcupdate | (branch & zero);

    maindec maindec(
        .clk      (clk),
        .reset    (reset),
        .op       (op),
        .pcupdate (pcupdate),
        .branch   (branch),
        .regwrite (regwrite),
        .memwrite (memwrite),
        .irwrite  (irwrite),
        .resultsrc(resultsrc),
        .alusrcb  (alusrcb),
        .alusrca  (alusrca),
        .adrsrc   (adrsrc),
        .aluop    (aluop)
    );

    aludec aludec(
        .opb5      (op[5]),
        .funct3    (funct3),
        .funct7b5  (funct7b5),
        .ALUOp     (aluop),
        .ALUControl(alucontrol)
    );

    instrdec instrdec(
        .op     (op),
        .ImmSrc (immsrc)
    );

endmodule

module maindec(
    input  logic        clk,
    input  logic        reset,
    input  logic [6:0]  op,
    output logic        pcupdate,
    output logic        branch,
    output logic        regwrite,
    output logic        memwrite,
    output logic        irwrite,
    output logic [1:0]  resultsrc,
    output logic [1:0]  alusrcb,
    output logic [1:0]  alusrca,
    output logic        adrsrc,
    output logic [1:0]  aluop
);

    typedef enum logic [3:0] {
        S0_FETCH    = 4'd0,
        S1_DECODE   = 4'd1,
        S2_MEMADR   = 4'd2,
        S3_MEMREAD  = 4'd3,
        S4_MEMWB    = 4'd4,
        S5_MEMWRITE = 4'd5,
        S6_EXECUTER = 4'd6,
        S7_ALUWB    = 4'd7,
        S8_EXECUTEI = 4'd8,
        S9_JAL      = 4'd9,
        S10_BEQ     = 4'd10
    } statetype;

    statetype state, nextstate;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= S0_FETCH;
        else       state <= nextstate;
    end

    always_comb begin
        case (state)
            S0_FETCH:    nextstate = S1_DECODE;

            S1_DECODE:
                case (op)
                    7'b0000011,               // lw
                    7'b0100011: nextstate = S2_MEMADR;    // sw
                    7'b0110011: nextstate = S6_EXECUTER;  // R-type
                    7'b0010011: nextstate = S8_EXECUTEI;  // I-type ALU
                    7'b1101111: nextstate = S9_JAL;       // jal
                    7'b1100011: nextstate = S10_BEQ;      // beq
                    default:    nextstate = S0_FETCH;
                endcase

            S2_MEMADR:
                case (op)
                    7'b0000011: nextstate = S3_MEMREAD;   // lw
                    7'b0100011: nextstate = S5_MEMWRITE;  // sw
                    default:    nextstate = S0_FETCH;
                endcase

            S3_MEMREAD:  nextstate = S4_MEMWB;
            S4_MEMWB:    nextstate = S0_FETCH;
            S5_MEMWRITE: nextstate = S0_FETCH;
            S6_EXECUTER: nextstate = S7_ALUWB;
            S7_ALUWB:    nextstate = S0_FETCH;
            S8_EXECUTEI: nextstate = S7_ALUWB;
            S9_JAL:      nextstate = S7_ALUWB;
            S10_BEQ:     nextstate = S0_FETCH;
            default:     nextstate = S0_FETCH;
        endcase
    end

    always_comb begin
        pcupdate  = 1'b0;
        branch    = 1'b0;
        regwrite  = 1'b0;
        memwrite  = 1'b0;
        irwrite   = 1'b0;
        resultsrc = 2'b00;
        alusrcb   = 2'b00;
        alusrca   = 2'b00;
        adrsrc    = 1'b0;
        aluop     = 2'b00;

        case (state)
            S0_FETCH: begin
                adrsrc    = 1'b0;   // Adres = PC
                irwrite   = 1'b1;   // IR'a yaz
                alusrca   = 2'b00;  // SrcA = PC
                alusrcb   = 2'b10;  // SrcB = 4
                aluop     = 2'b00;  // ALU: topla (PC+4)
                resultsrc = 2'b10;  // Result = ALUResult (direkt, register bypass)
                pcupdate  = 1'b1;   // PC yaz
            end

            S1_DECODE: begin
                alusrca = 2'b01;  // SrcA = OldPC
                alusrcb = 2'b01;  // SrcB = ImmExt
                aluop   = 2'b00;  // ALU: topla
            end

            S2_MEMADR: begin
                alusrca = 2'b10;  // SrcA = A (rs1)
                alusrcb = 2'b01;  // SrcB = ImmExt
                aluop   = 2'b00;  // ALU: topla
            end

            S3_MEMREAD: begin
                resultsrc = 2'b00;  // adres için ALUOut kullan
                adrsrc    = 1'b1;   // Adres = ALUOut
            end

            S4_MEMWB: begin
                resultsrc = 2'b01;  // Result = Data (bellekten gelen)
                regwrite  = 1'b1;   // Register'a yaz
            end

            S5_MEMWRITE: begin
                resultsrc = 2'b00;
                adrsrc    = 1'b1;   // Adres = ALUOut
                memwrite  = 1'b1;   // Belle?e yaz
            end

            S6_EXECUTER: begin
                alusrca = 2'b10;  // SrcA = A (rs1)
                alusrcb = 2'b00;  // SrcB = B (rs2)
                aluop   = 2'b10;  // ALU: funct3/funct7'e bak
            end

            S7_ALUWB: begin
                resultsrc = 2'b00;  // Result = ALUOut
                regwrite  = 1'b1;   // Register'a yaz
            end

            S8_EXECUTEI: begin
                alusrca = 2'b10;  // SrcA = A (rs1)
                alusrcb = 2'b01;  // SrcB = ImmExt
                aluop   = 2'b10;  // ALU: funct3'e bak
            end

            S9_JAL: begin
                alusrca   = 2'b01;  // SrcA = OldPC
                alusrcb   = 2'b10;  // SrcB = 4
                aluop     = 2'b00;  // ALU: topla (OldPC + 4 = dönü? adresi)
                resultsrc = 2'b00;  // PC = ALUOut (PCTarget, Decode'da hesapland?)
                pcupdate  = 1'b1;   // PC yaz
            end

            S10_BEQ: begin
                alusrca   = 2'b10;  // SrcA = A (rs1)
                alusrcb   = 2'b00;  // SrcB = B (rs2)
                aluop     = 2'b01;  // ALU: ç?kar
                resultsrc = 2'b00;  // PC kayna?? = ALUOut (PCTarget)
                branch    = 1'b1;   // Ko?ullu PC yazma
            end

            default: begin
            end
        endcase
    end

endmodule

module aludec(
    input  logic        opb5,
    input  logic [2:0]  funct3,
    input  logic        funct7b5,
    input  logic [1:0]  ALUOp,
    output logic [2:0]  ALUControl
);

    logic RtypeSub;
    assign RtypeSub = funct7b5 & opb5;

    always_comb
        case (ALUOp)
            2'b00: ALUControl = 3'b000; // add  (lw/sw adres hesab?)
            2'b01: ALUControl = 3'b001; // subtract (beq kar??la?t?rma)
            default:                    // R-type veya I-type ALU
                case (funct3)
                    3'b000: if (RtypeSub)
                                ALUControl = 3'b001; // sub
                            else
                                ALUControl = 3'b000; // add / addi
                    3'b010: ALUControl = 3'b101; // slt / slti
                    3'b110: ALUControl = 3'b011; // or  / ori
                    3'b111: ALUControl = 3'b010; // and / andi
                    default: ALUControl = 3'bxxx;
                endcase
        endcase

endmodule

module instrdec(
    input  logic [6:0]  op,
    output logic [1:0]  ImmSrc
);

    always_comb
        case (op)
            7'b0110011: ImmSrc = 2'bxx; // R-type (don't care)
            7'b0010011: ImmSrc = 2'b00; // I-type ALU (addi, andi, ori...)
            7'b0000011: ImmSrc = 2'b00; // lw
            7'b0100011: ImmSrc = 2'b01; // sw
            7'b1100011: ImmSrc = 2'b10; // beq
            7'b1101111: ImmSrc = 2'b11; // jal
            default:    ImmSrc = 2'bxx;
        endcase

endmodule