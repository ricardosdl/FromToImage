EnableExplicit

;the first 3 pixels (9 bytes for 24-bit image) contains
;the size of the original file, the actual size will be
;in Size, padding is just to adjust the size
Structure TImageHeader
  Size.q
  Padding.a
EndStructure

#ImageHeaderSize = SizeOf(TImageHeader)

Procedure ConvertImageHeaderToBytesArray(*ImageHeader.TImageHeader, Array BytesArray.b(1))
  Protected Offset.a
  For Offset = 0 To #ImageHeaderSize - 1
    BytesArray(Offset) = PeekB(*ImageHeader + Offset)
  Next
EndProcedure

Procedure ConvertBytesToColor(Byte1.b = 0, Byte2.b = 0, Byte3.b = 0)
  ProcedureReturn RGB(Byte1, Byte2, Byte3)
EndProcedure

Procedure ConvertBufferToImage(*Buffer, BufferSize.q)
  Protected ImageHeader.TImageHeader\Size = BufferSize
  ImageHeader\Padding = 0
  
  ;each three bytes can be stored in one pixel
  Protected NumPixels.q = Round(BufferSize / 3, #PB_Round_Up)
  ;more pixels to store the orignal file size at the beggining
  NumPixels + #ImageHeaderSize / 3
  
  Protected SquareRootNumPixels.f = Sqr(NumPixels)
  Protected ImageWidth.q = Round(SquareRootNumPixels, #PB_Round_Up)
  Protected ImageHeight.q = ImageWidth
  
  Protected Image = CreateImage(#PB_Any, ImageWidth, ImageHeight, 24)
  If Image = 0
    ProcedureReturn #False
  EndIf
  
  Protected BufferOfsset.q;offset so we can read *buffer byte by byte
  
  StartDrawing(ImageOutput(Image))
  Protected ImageX, ImageY
  Protected Color
  
  ;plot 3 pixels (9 bytes) to the beggining of the image
  ;that will contain the input file size
  Protected ByteOffset = 0
  Dim BytesArrayImageHeader.b(#ImageHeaderSize - 1)
  ConvertImageHeaderToBytesArray(@ImageHeader, BytesArrayImageHeader())
  For ByteOffset = 0 To (#ImageHeaderSize / 3) - 1
    Protected Byte1.b, Byte2.b, Byte3.b
    Byte1 = BytesArrayImageHeader(ByteOffset * 3 + 0)
    Byte2 = BytesArrayImageHeader(ByteOffset * 3 + 1)
    Byte3 = BytesArrayImageHeader(ByteOffset * 3 + 2)
    Color = ConvertBytesToColor(Byte1, Byte2, Byte3)
    ImageX = (ByteOffset / 3) % ImageWidth
    ImageY = (ByteOffset/ 3) / ImageHeight
    Plot(ImageX, ImageY, Color)
  Next
  
  Protected CurrentNumBytes.a = 0, Dim CurrentBytes.b(2)
  
  For BufferOfsset = 0 To BufferSize - 1
    Protected *CurrentByte.Byte = *Buffer + BufferOfsset
    CurrentNumBytes + 1
    CurrentBytes(CurrentNumBytes - 1) = *CurrentByte\b
    If CurrentNumBytes < 3
      Continue
    Else
      CurrentNumBytes = 0
      Color = RGB(CurrentBytes(0), CurrentBytes(1), CurrentBytes(2))
      ImageX = ((ByteOffset + BufferOfsset) / 3) % ImageWidth
      ImageY = ((ByteOffset + BufferOfsset) / 3) / ImageHeight
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