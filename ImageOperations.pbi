EnableExplicit

;the first 3 pixels (9 bytes for 24-bit image) contains
;the size of the original file, the actual size will be
;in Size, padding is just to adjust the size
Structure TImageHeader
  Size.q
  Padding.a
EndStructure


Procedure ConvertBufferToImage(*Buffer, BufferSize.q)
  Protected ImageHeader.TImageHeader\Size = BufferSize
  ImageHeader\Padding = 0
  
  ;each three bytes can be stored in one pixel
  Protected NumPixels.q = Round(BufferSize / 3, #PB_Round_Up)
  ;more pixels to store the orignal file size at the beggining
  NumPixels + SizeOf(ImageHeader) / 3
  
  Protected SquareRootNumPixels.f = Sqr(NumPixels)
  Protected ImageWidth.q = Round(SquareRootNumPixels, #PB_Round_Up)
  Protected ImageHeight.q = ImageWidth
  
  Protected Image = CreateImage(#PB_Any, ImageWidth, ImageHeight, 24)
  If Image = 0
    ProcedureReturn #False
  EndIf
  
  Protected BufferOfsset.q;offset so we can read *buffer byte by byte
  
  StartDrawing(ImageOutput(Image))
  Protected CurrentNumBytes.a = 0, Dim CurrentBytes.b(2)
  Protected Color
  Protected ImageX, ImageY
  For BufferOfsset = 0 To BufferSize - 1
    Protected *CurrentByte.Byte = *Buffer + BufferOfsset
    CurrentNumBytes + 1
    CurrentBytes(CurrentNumBytes - 1) = *CurrentByte\b
    If CurrentNumBytes < 3
      Continue
    Else
      CurrentNumBytes = 0
      Color = RGB(CurrentBytes(0), CurrentBytes(1), CurrentBytes(2))
      ImageX = (BufferOfsset / 3) % ImageWidth
      ImageY = (BufferOfsset / 3) / ImageHeight
      Plot(ImageX, ImageY, Color)
      CurrentBytes(0) = 0 : CurrentBytes(1) = 0 : CurrentBytes(2) = 0
    EndIf
  Next
  
  ;save the pending bytes on the image
  If CurrentNumBytes <> 0
    BufferOfsset + 1
    Select CurrentNumBytes
      Case 1:
        Color = RGB(CurrentBytes(0), 0, 0)
      Case 2:
        Color = RGB(CurrentBytes(0), CurrentBytes(1), 0)
    EndSelect
    ImageX = (BufferOfsset / 3) % ImageWidth
    ImageY = (BufferOfsset / 3) / ImageHeight
    Plot(ImageX, ImageY, Color)
  EndIf
  StopDrawing()
  
  ProcedureReturn Image
EndProcedure

DisableExplicit