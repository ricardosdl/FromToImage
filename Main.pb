EnableExplicit

IncludeFile "FileOperations.pbi"
IncludeFile "ImageOperations.pbi"

Enumeration TProgramUsage
  #ConvertToImageNoOutputImageName
  #ConvertToImageOutputImageName
  #ConvertBack
EndEnumeration

Procedure GetProgramParameters(NumParameters.a, List Parameters.s())
  ClearList(Parameters())
  While(NumParameters)
    Protected Paramter.s = ProgramParameter()
    AddElement(Parameters())
    Parameters() = Paramter
    NumParameters - 1
  Wend
EndProcedure

Procedure.a HasConvertBackParameter(List Parameters.s())
  ForEach Parameters()
    Protected CurrentParameter.s = LCase(Parameters())
    If CurrentParameter = "/convertback"
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

Procedure.a IsValidPathInputFile(PathInputFile.s)
  ProcedureReturn Bool(FileSize(PathInputFile) >= 0)
EndProcedure

Procedure PrintProgramUsage()
  PrintN("usage: fromtoimage.exe path_input_file")
  PrintN("usage: fromtoimage.exe path_input_file output_image_name")
  PrintN("usage: fromtoimage.exe path_input_image output_file_name /convertback")
EndProcedure

Procedure ConvertToImageNoOutputImageName(PathInputFile.s)
  If Not IsValidPathInputFile(PathInputFile)
    PrintN(PathInputFile + " couldn't be opened.")
    ProcedureReturn #False
  EndIf
  
  BufferSize.Quad;will store the size of the returned buffer
  *InputFileBuffer = ReadFileToMemoryBuffer(PathInputFile, @BufferSize)
  If *InputFileBuffer = #Null
    PrintN("couldn't load file " + PathInputFile + " in memory")
    ProcedureReturn #False
  EndIf
  
  Protected Image = ConvertBufferToImage(*InputFileBuffer, BufferSize\q)
  
  SaveImage(Image, "out.bmp", #PB_ImagePlugin_BMP, 7, 24)
  
  
  
  
  
  
  
  
  
EndProcedure



Global ProgramUsage.b = -1
Global NewList ProgramParameters.s()


If OpenConsole() = 0
  End 1
EndIf

Define NumParameters.a = CountProgramParameters()

If NumParameters = 0
  PrintProgramUsage()
  End 0
EndIf

;we only call it once, probably will erase the programparameters() list if called twice
GetProgramParameters(NumParameters, ProgramParameters())

Select NumParameters
  Case 1:
    ProgramUsage = #ConvertToImageNoOutputImageName
  Case 2:
    ProgramUsage = #ConvertToImageOutputImageName
  Case 3:
    ProgramUsage = #ConvertBack
  Default
    ProgramUsage = #ConvertBack
EndSelect

If ProgramUsage = #ConvertBack
  ;one of the parameters must be /convertback
  If Not HasConvertBackParameter(ProgramParameters())
    PrintProgramUsage()
    End 2
  EndIf
  
EndIf

Select ProgramUsage
  Case #ConvertToImageNoOutputImageName
    ConvertToImageNoOutputImageName(ProgramParameters())
  Default
    End 0
EndSelect

Input()






