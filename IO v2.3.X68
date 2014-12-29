*-----------------------------------------------------------
* Title      : IO portion of disassembler
* Written by : Dan Heizer
* Date       : 11/12
* Description: 
*   1. Prompts user for start and end addresses
*   2. Ensures that entered addresses are valid
*   3. Converts the addresses from ascii to hex.
*   4. Loops from start to end, printing each address as a 6 digit num
*   5. Every 30 lines of output, the user must press enter to continue.
*   6. Once the end is reached, the user is asked if they would like to run again.
Note: Written for easy68K, a free Motorola 6800 emulator.
*-----------------------------------------------------------
    ORG    $1000
START 
    JSR WelcomeUser         * Print welcome message, only do it once.

RequestAddr
*--------------- GET AND CONVERT START ADDR ---------------
    JSR RequestStart        * prompts for start address
    LEA StartAddrSpace, A1
    MOVE.B #2, D0           * Get input from keyboard, D1 = len
    TRAP #15                * Sets A1 to the input string
    CMP #$6, D1             * 6 chars max
    BGT InvalidAddress      * If D1 > 6, address too big
    
    JSR ConvertAsciiToHex   * Converts string at A1 to hex
    MOVE.L D7, StartAddr    * Move converted address to startaddr
*----------- CHECK STARTING ADDRESS IS EVEN ---------------
    ASR.B #1, D7            * If last bit is one, then the address is odd.
    BCS OddAddress          * If the carry bit is set, print error and prompt again.
    MOVE.L #0, D7           * Clear D7
    

*------------- GET AND CONVERT END ADDR -------------------
    JSR RequestEnd          * Prompts for end address
    LEA EndAddrSpace, A1
    MOVE.B #2, D0
    TRAP #15                * Get input from keyboard, Stores at A1 and len at D1
    JSR ConvertAsciiToHex   * Converts string at A1 to hex
    MOVE.L D7, EndAddr      * move ending address
    
*----------- CHECK ENDING ADDRESS IS EVEN -----------------
    ASR.B #1, D7            * If last bit is one, then the address is odd.
    BCS OddAddress          * If the carry bit is set, print error and prompt again.
    CLR.L D7                * Clear D7
*---------------- Ensure starting < ending ----------------
    CLR.L D0
    CLR.L D1
    MOVE.L StartAddr, D0    * Start Addr->D0
    MOVE.L EndAddr, D1      * Ending address D1 
    CMP.L D0, D1            * Is start > end
    BLE InvalidAddress      


*----------- Initialize to loop through memory ------------
    MOVE.L (StartAddr), A2  * USING A2 TO TRAVERSE MEMORY
    MOVE.B #0, LineCount * Initialize line count
    
*----------- Loop through memory and dissassemble ---------
DisLoop
    MOVE.W A2, D1           * Copy address we're using from a2 to D1
    JSR PrintHexAddr        * Print hex num in D1
    ADDQ.W #4, A2           * Move to the next word
    ADDQ.B #1, LineCount    * Increment line counter
    MOVE.W A2, D0           * Copy current addr to D0 to print
    CMP.L EndAddr,D0        * Compare current to end
    BGE ReachedEnd          * If we reached the endaddr, we're done
    CMP.W #$FFFF, (A2)      * Make sure it's not FFFF
    BNE NotFFFF     
    LEA FFFFMsg, A1         * Print FFFF
    MOVE.B #14, D0
    TRAP #15
    
    ********************************
    * Disassemble stuff goes here  *
    ********************************
    * This is where my group memebers would add code that 
    * dissassembles the instruction pointed to by A2.
    
    
NotFFFF
    JSR EndLine             * Skip a line
    JMP Check30Line         * Check if we've gone 30 lines
    
NextInstruction
    JMP DisLoop             * Get another instruction
    
ReachedEnd
    JSR EndLine
    MOVE.L EndAddr, D1      * Print end address as last line
    JSR PrintHexAddr
    JSR EndLine
    LEA FinishMsg,A1        * Print part 1 finish message
    MOVE.B #14,D0
    TRAP #15
PromptUser    
    LEA RunAgainPrompt,A1   * Print rest of finish message
    MOVE.B #14,D0           *  prompt to enter y/n
    TRAP #15                * y is ascii $79, n is 4E
    
    LEA InputSpace, A1
    MOVE.B #2, D0      
    TRAP #15                 * Get input
    CMP.B #$79, (InputSpace) * Did you enter y?
    BEQ GoAgain
    
    CMP.B #$6E, (InputSpace) * Did you enter n?
    BEQ EXIT
    
    LEA FinishMsgError, A1   * Print error message, prompt again
    MOVE.B #14, D0
    TRAP #15
    JMP PromptUser    
    

GoAgain             * Clear everything in prepration to run again
    JSR EndLine     * Print an empty line
    CLR.L StartAddr
    CLR.L EndAddr
    CLR.L StartAddrSpace
    CLR.L D7
    CLR.L D6
    CLR.L D5
    CLR.L D4
    CLR.L D3
    CLR.L D2
    CLR.L D1
    CLR.L D0
    CLR.L EndAddrSpace
    CLR.B LineCount     
    CLR.B InputSpace 
  
    JMP RequestAddr   
*---------------------------------------------------------------------
*------------------------------End of "Main"--------------------------
*---------------------------------------------------------------------

EXIT *Ask if user wants to go again
    LEA ThankMsg, A1
    MOVE.B #14, D0
    TRAP #15
    MOVE.B #9, D0       * Exit
    TRAP #15


*--------------*CONVERTING ASCII STRING TO HEX METHOD*--------------*
* YOU MUST SET
* A1: Address of the string we're converting, Converts in place
* D1: The length of the string
*   Note: Trap #2 (reading from keyboard) sets this automatically
* --------------------------*NOTES*---------------------------------*
* D3 is used as a counter
* D5 used to count down from 6 
* If the string has an invalid character (ie, not a digit or ABCDEF)
*   it will print an error and jump to the end of the method.
*-------------------------------------------------------------------*
ConvertAsciiToHex
    MOVE.B #0, D3  * Initialize D3
    MOVE.B D1, D5  * Move length into D5
    SUBQ.B #$1,D5
    JSR ConversionLoop
ConversionLoop 
    MOVEQ.L #0, D2                * CLR D2
    CMP.B D3, D1                  * Counter == length
    BEQ Converted                 * If we've converted the entire string, we're done.
    MOVE.B (A1), D2               * Move the char pointed to by A1 to D2
    JSR ConvertAsciiToHexHelper   * Increments counter, Converts char
        
    MOVE.B D5, D6           * Shift each char, counting down from length
    MULU.W #$4, D6
    SUBQ.W #$1, D5          * Decrement
    LSL.L D6, D2


    ADD.L D2, D7            * Move to D7
    MOVEQ.L #$0, D2         * CLR
    ADDA.W #$1, A1          * Increment the address
    ADDQ.B #1, D3           * Increment our counter
    JMP ConversionLoop
    
ConvertAsciiToHexHelper * Converts D2 from an ASCII char to a hex number.   
    CMP.B #$30,D2       * Ascii 0 is $30
    BLT InvalidChar     * If it's less than 0, invalid
    CMP.B #$46, D2      * Ascii F is $46
    BGT LowerCase       * If greater than F, It's either lowercase or invalid
    CMP.B #$39, D2      * Check for char X where 9<X<A
    BGT InvalidSuspect  * If ascii value is greater than 9, make sure its valid
Valid   *Char is valid
    CMP.B #$40,D2       * If the ascii number at D2 is less than hex40, it's a digit
    BGT ConvAsciiLetter
    BLT ConvAsciiNum     
ConvAsciiNum
    SUB #$30,D2          * Convert the char (0-9) from ascii to hex 
    RTS                  * Return
ConvAsciiLetter
    SUB #$37, D2         * Convert the char (A-F) from ascii to hex
    RTS                  * return
ConvLowerCase
    SUB #$57, D2         * Convert the char (a-f) from ascii to hex
    RTS                  * return
LowerCase                *Allow a b c d e f
    CMP.B #$61, D2       * $61 = a
    BLT InvalidChar      * Greater than F, less than a
    
    CMP.B #$66, D2       * $66 = f
    BGT InvalidChar      * greater than f
    
    JMP ConvLowerCase    * Not less than a, or greater than f

InvalidSuspect           * Will be reached for all Letters
    CMP.B #$41, D2       * A is 41, reached if ascii is >9(ascii $39)
    BLT InvalidChar      * If the value is >9 and <A, it's invalid
    JMP Valid
InvalidChar
    LEA InvalidMsg, A1  * Print error
    MOVE.B #14, D0
    TRAP #15
    JMP GoAgain     * Exit the method
Converted
    RTS                 * Hex conversion done          

RequestStart            * Request start addr
    LEA StartAddrMsg, A1
    MOVE.B #14, D0      * Prompt user for address
    TRAP #15
    RTS                 * Return
        
RequestEnd              * Request ending address
    LEA EndAddrMsg, A1
    MOVE.B #14, D0
    TRAP #15            * Prompt User for address
    RTS                 * Return
    
*-----------------------------InvalidAddress-----------------------------
* Called when the hex conversion method determines that
* the address entered was invalid.
* DOES: Prints an error message and starts over.
* USES: D0, A1
InvalidAddress          * Print error and start over
    LEA  InvalidMsg, A1 
    MOVE.B #14, D0
    TRAP #15
    CLR.L StartAddr     * Clear the fields used to process an address
    CLR.L EndAddr
    CLR.L StartAddrSpace
    CLR.L EndAddrSpace
    JMP GoAgain         * Prompt for address again

*----------------------------PrintHexAddr--------------------------------
* DOES: Prints the unsigned number in D1 in base 16.
* Adds 0s in front of the number so that the result is always 6 digits.
* USES: D0,D1,D2,A1 
PrintHexAddr          
    CMP.L #$F, D1     * If less than F, 1 digit
    BLE Five0                 
    CMP.L #$FF, D1    * If Less than FF, 2 digits
    BLE Four0
    CMP.L #$FFF, D1   * If Less than FFF, 3 digits
    BLE Three0
    CMP.L #$FFFF, D1  * If Less than FFFF, 4 digits
    BLE Two0
    CMP.L #$FFFFF, D1 * If Less than FFFFF, 5 digits
    BLE One0    
    
PrintedZeros * make sure this stays below printHexAddr
    MOVE.W #15, D0
    MOVE.B #16, D2
    TRAP #15
    RTS
One0                  * 5 digits, so one 0 is printed
    LEA One0Msg, A1
    MOVE.B #14, D0
    TRAP #15
    JMP PrintedZeros
Two0                  * 4 digits, so two 0s is printed
    LEA Two0Msg, A1
    MOVE.B #14, D0
    TRAP #15
    JMP PrintedZeros
Three0                * 3 digits, so three 0s are printed
    LEA Three0Msg, A1
    MOVE.B #14, D0
    TRAP #15
    JMP PrintedZeros
Four0                 * 2 digits, so 4 zeros 0s printed
    LEA Four0Msg, A1
    MOVE.B #14, D0
    TRAP #15
    JMP PrintedZeros
Five0                 * 1 digit, so 5 zeros 0s printed
    LEA Five0Msg, A1
    MOVE.B #14, D0
    TRAP #15
    JMP PrintedZeros

EndLine              *Print a new line
    LEA blankLineMsg, A1
    MOVE.B #14,D0
    TRAP #15
    RTS

WelcomeUser
    LEA GreetingMsg, A1
    MOVE.B #14, D0
    TRAP #15
    RTS

OddAddress  * If an address is odd, Print an error and ask for new ones
    LEA OddAddressMsg, A1
    MOVE.B #14, D0
    TRAP #15
    JMP GoAgain
Check30Line * If the line count is 30, make user press enter
    CMP.B #$1E, (LineCount) * Check if we've gone 30 lines
    BNE NextInstruction
    LEA ThirtyLinesMsg, A1
    MOVE.B #14,D0
    TRAP #15                * Print message
    LEA InputSpace, A1      * Read it to ascii chars
    MOVE.B #2, D0           * Force user to enter 
    TRAP #15
    MOVE.W #0, LineCount    * Clear the counter to count to 30 again
    JMP NextInstruction

* Messages to ensure addresses are printed as 6 characters
One0Msg             *Used when the address is 5 digits
    DC.B '0',0
Two0Msg             *Used when the address is 4 digits
    DC.B '00',0
Three0Msg           *Used when the address is 3 digits
    DC.B '000',0
Four0Msg            *Used when the address is 2 digits
    DC.B '0000',0
Five0Msg            *Used when the address is 1 digits
    DC.B '00000',0
OddAddressMsg 
    DC.B 'ERROR: Please enter even addresses.',0
ThirtyLinesMsg
    DC.B 'Press enter to continue...',CR,LF,0
BlankLineMsg
    DC.B '',CR,LF,0
GreetingMsg
    DC.B 'Welcome to the Free Ice Climbers Disassembler', CR, LF, 0
StartAddrMsg 
    DC.B 'Enter Starting Address: ',0
EndAddrMsg   
    DC.B 'Enter Ending Address  : ',0
FinishMsg    
    DC.B 'Done. ',0
RunAgainPrompt 
    DC.B 'Run again? (y/n)',CR,LF,0
ThankMsg
    DC.B 'Thank you for using the FreeIC disassembler!',CR,LF,0
FinishMsgError
    DC.B 'ERROR: Please enter y or n.',CR,LF,0
InvalidMsg 
    DC.B 'ERROR: Please enter a 6-digit Hex address using only valid characters.',CR,LF,0
FFFFMsg
    DC.B ' FFFF',0
StartAddrSpace DC.L 0 * Where user input is stored (ascii)
StartAddr      DC.L 0 * Where the converted (ascii->hex) input is stored
EndAddrSpace   DC.L 0 * Where user input is stored (ascii)
EndAddr        DC.L 0 * Where the converted (ascii->hex) input is stored
LineCount      DC.B 0 * Incremented every time an address is printed. At 30, skip line.
InputSpace     DC.B 0 
CR EQU $0D // Carriage Return
LF EQU $0A //Line Feed
    END    START      
