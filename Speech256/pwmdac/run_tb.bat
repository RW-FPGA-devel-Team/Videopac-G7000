mkdir bin
del bin\pwmdac.vvp
C:\iverilog\bin\iverilog -o bin\pwmdac.vvp -m va_math -g2005 -s PWMDAC_TB pwmdac.v pwmdac_tb.v
cd bin
C:\iverilog\bin\vvp pwmdac.vvp
cd ..
