EnableExplicit

#File_Buffer_Read_Size = 4096;in bytes

;reads the contents from pathinputfile into a memory buffer
;puts the size of the buffer in *BufferSize
;returns the buffer address, or #null if some error occurred
Procedure.i ReadFileToMemoryBuffer(PathInputFile.s, *BufferSize.Quad)
  Protected InputFile = ReadFile(#PB_Any, PathInputFile)
  If InputFile = 0
    ProcedureReturn #Null
  EndIf
  
  Protected InputFileSize.q = Lof(InputFile)
  Protected *FileBuffer = AllocateMemory(InputFileSize, #PB_Memory_NoClear)
  If *FileBuffer = 0
    CloseFile(InputFile)
    ProcedureReturn #Null
  EndIf
  
  Protected *FileBufferPos = *FileBuffer
  
  Repeat
    Protected BytesRead = ReadData(InputFile, *FileBufferPos, #File_Buffer_Read_Size)
    *FileBufferPos + BytesRead
  Until Eof(InputFile)
  
  CloseFile(InputFile)
  *BufferSize\q = InputFileSize
  ProcedureReturn *FileBuffer
  
EndProcedure

DisableExplicit