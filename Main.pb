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

Procedure ConvertToImageNoOutputImageName(PathInputFile.s, PathOutputImage.s = "")
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
  
  If Image = 0
    PrintN("error: couldn't create image")
    ProcedureReturn #False
  EndIf
  
  Protected OutputImagePath.s = "out.bmp"
  If Len(PathOutputImage) > 0
    OutputImagePath = PathOutputImage
  EndIf
  
  Protected IsImageSaved = SaveImage(Image, OutputImagePath, #PB_ImagePlugin_BMP, 7, 24)
  If IsImageSaved = 0
    PrintN("error: couldn't save image")
    ProcedureReturn #False
  EndIf
  
  PrintN("success: image saved as '" + OutputImagePath + "'")
  ProcedureReturn #True
EndProcedure

Procedure ConvertBack(PathInputImage.s, PathOutputFile.s)
  If Not IsValidPathInputFile(PathInputImage)
    PrintN(PathInputImage + " couldn't be opened.")
    ProcedureReturn #False
  EndIf
  
  Protected InputImage = LoadImage(#PB_Any, PathInputImage)
  If InputImage = 0
    PrintN("error: error reading input image")
    ProcedureReturn #False
  EndIf
  
  ImageHeader.TImageHeader
  ExtractImageHeader(InputImage, @ImageHeader)
  
  *Buffer = ConvertImageToBuffer(InputImage, ImageHeader\Size)
  If *Buffer = #Null
    PrintN("error: couldn't allocate file on memory")
    ProcedureReturn #False
  EndIf
  
  Protected IsBufferSavedToFile = SaveMemoryBufferToFile(*Buffer, ImageHeader\Size, PathOutputFile)
  If Not IsBufferSavedToFile
    PrintN("error: couldn't save output file")
    ProcedureReturn #False
  EndIf
  
  FreeMemory(*Buffer)
  ProcedureReturn #True
  
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
    Define IsSucess = ConvertToImageNoOutputImageName(ProgramParameters())
    If IsSucess = 0
      Input()
      End 3
    Else
      Input()
      End 0
    EndIf
  Case #ConvertToImageOutputImageName
    Define PathInputFile.s
    FirstElement(ProgramParameters())
    PathInputFile = ProgramParameters()
    
    Define PathOutputImage.s
    NextElement(ProgramParameters())
    PathOutputImage = ProgramParameters()
    
    Define IsSucess = ConvertToImageNoOutputImageName(PathInputFile, PathOutputImage)
    If IsSucess = 0
      Input()
      End 3
    Else
      Input()
      End 0
    EndIf
    
  Case #ConvertBack
    Define PathInputImage.s
    FirstElement(ProgramParameters())
    PathInputImage = ProgramParameters()
    
    Define PathOutputFile.s
    NextElement(ProgramParameters())
    PathOutputFile = ProgramParameters()
    
    ConvertBack(PathInputImage, PathOutputFile)
    
    Input()
  
    
  Default
    End 0
EndSelect






