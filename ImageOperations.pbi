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
  
  ;after saving the imageheader, ByteOffset will store how many
  ;bytes we already saved on the image
  Protected ByteOffset = 0
  Dim BytesArrayImageHeader.b(#ImageHeaderSize - 1)
  ConvertImageHeaderToBytesArray(@ImageHeader, BytesArrayImageHeader())
  For ByteOffset = 0 To (#ImageHeaderSize - 1) Step 3
    Protected Byte1.b, Byte2.b, Byte3.b
    ;reads bytes from the imageheader, 3 bytes at a time
    Byte1 = BytesArrayImageHeader(ByteOffset + 0)
    Byte2 = BytesArrayImageHeader(ByteOffset + 1)
    Byte3 = BytesArrayImageHeader(ByteOffset + 2)
    Color = ConvertBytesToColor(Byte1, Byte2, Byte3)
    ;calculate the position on the image using the byteoffset
    ImageX = (ByteOffset / 3) % ImageWidth
    ImageY = (ByteOffset/ 3) / ImageHeight
    Plot(ImageX, ImageY, Color)
  Next
  
  ;now we'll save the bytes inside the *buffer on the image
  ;the same as above: 3 bytes per pixel
  
  ;CurrentNumBytes stores how many bytes we read from the buffer
  ;when it reaches 3 we convert it to a pixel and plot on the image
  ;CurrentBytes store the actual bytes values
  Protected CurrentNumBytes.a = 0, Dim CurrentBytes.b(2)
  
  For BufferOfsset = 0 To BufferSize - 1
    Protected *CurrentByte.Byte = *Buffer + BufferOfsset
    CurrentNumBytes + 1
    CurrentBytes(CurrentNumBytes - 1) = *CurrentByte\b
    If CurrentNumBytes < 3
      ;we still don't have 3 bytes, so we keep reading them from *Buffer
      Continue
    Else
      ;got the 3 bytes to generate a color so we can save it as pixel on the image
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
    ;the number of bytes in *Buffer might not be divisible by 3, so 
    ;we are left with one or two bytes to save 
    BufferOfsset + 1
    Select CurrentNumBytes
      Case 1:
        ;only 1 byte left
        Color = RGB(CurrentBytes(0), 0, 0)
      Case 2:
        ;2 bytes left
        Color = RGB(CurrentBytes(0), CurrentBytes(1), 0)
    EndSelect
    ImageX = ((ByteOffset + BufferOfsset) / 3) % ImageWidth
    ImageY = ((ByteOffset + BufferOfsset) / 3) / ImageHeight
    Plot(ImageX, ImageY, Color)
  EndIf
  StopDrawing()
  
  ProcedureReturn Image
EndProcedure

Procedure ExtractImageHeader(ImageNum.i, *ImageHeader.TImageHeader)
  Protected ImageWidth, ImageHeight
  ImageWidth = ImageWidth(ImageNum)
  ImageHeight = ImageHeight(ImageNum)
  
  Dim Bytes.b(#ImageHeaderSize - 1)
  StartDrawing(ImageOutput(ImageNum))
  Protected CurrentByte
  For CurrentByte = 0 To #ImageHeaderSize - 1 Step 3;3 bytes per pixel
    Protected PosByte1.b = CurrentByte + 0
    Protected PosByte2.b = CurrentByte + 1
    Protected PosByte3.b = CurrentByte + 2
    
    Protected CurrentX = (PosByte1 / 3) % ImageWidth
    Protected CurrentY = (PosByte1 / 3) / ImageHeight
    
    ;Protected CurrentX2 = (PosByte2 / 3) % ImageWidth
    ;Protected CurrentY2 = (PosByte2 / 3) / ImageHeight
    
    ;Protected CurrentX3 = (PosByte3 / 3) % ImageWidth
    ;Protected CurrentY3 = (PosByte3 / 3) / ImageHeight
    
    Protected Color = Point(CurrentX, CurrentY)
    Bytes(PosByte1) = Red(Color)
    Bytes(PosByte2) = Green(Color)
    Bytes(PosByte3) = Blue(Color)
    
    
  Next
  
  For CurrentByte = 0 To #ImageHeaderSize - 1
    PokeB(*ImageHeader + CurrentByte, Bytes(CurrentByte))
  Next
  
  StopDrawing()
EndProcedure

Procedure.i ConvertImageToBuffer(ImageNum.i, *BufferSize.Quad)
  Protected ImageWidth, ImageHeight
  ImageWidth = ImageWidth(ImageNum)
  ImageHeight = ImageHeight(ImageNum)
  ;Protected 
  StartDrawing(ImageOutput(ImageNum))
  
  StopDrawing()
EndProcedure

DisableExplicit