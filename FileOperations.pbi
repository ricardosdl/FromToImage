EnableExplicit

#File_Buffer_RW_Size = 4096;in bytes

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
    Protected BytesRead = ReadData(InputFile, *FileBufferPos, #File_Buffer_RW_Size)
    *FileBufferPos + BytesRead
  Until Eof(InputFile)
  
  CloseFile(InputFile)
  *BufferSize\q = InputFileSize
  ProcedureReturn *FileBuffer
  
EndProcedure

Procedure.a SaveMemoryBufferToFile(*Buffer, *BufferSize, FileOutputPath.s)
  Protected OutputFile = OpenFile(#PB_Any, FileOutputPath)
  If OutputFile = 0
    ProcedureReturn #False
  EndIf
  
  Protected *BytesSaved = 0
  
  Protected BytesToWrite.q = #File_Buffer_RW_Size
  
  Repeat
    Protected BytesWritten = WriteData(OutputFile, *Buffer, BytesToWrite)
    *Buffer + BytesWritten
    *BytesSaved + BytesWritten
    
    
  Until #False
  
  
  
  
EndProcedure

DisableExplicit