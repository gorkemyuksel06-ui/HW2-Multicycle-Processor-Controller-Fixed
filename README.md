# HW2-Multicycle--Processor-Controller-Fixed

The ALU control encoding in the controller.tv file has been updated to match the RISC-V architecture from the book.



# **LAB 3: Multicycle RISC-V Processor Implementation**

Added all SystemVerilog modules (top, riscv, controller, datapath, memory) required for the Multicycle processor.  



Corrected controller.tv ALU control encodings to match the textbook architecture.



Fixed a critical datapath bug by tying the OldPC register update to the IRWrite signal, ensuring correct return addresses for jumps.



\* Verified functionality: System passes the memory write test (Mem\[100] == 25) in the testbench.






