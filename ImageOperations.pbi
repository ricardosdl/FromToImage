EnableExplicit

;the first 2 pixels (8 bytes for 32-bit image) contains
;the size of the original file, the actual size will be
;in Size, padding is just to adjust the size
Structure TImageHeader
  Size.q
EndStructure

#ImageHeaderSize = SizeOf(TImageHeader)

Procedure ConvertImageHeaderToBytesArray(*ImageHeader.TImageHeader, Array BytesArray.a(1))
  CopyMemory(*ImageHeader, @BytesArray(0), #ImageHeaderSize)
EndProcedure

Procedure.q ConvertBytesToColor(Byte1.a = 0, Byte2.a = 0, Byte3.a = 0, Byte4.a = 0)
  ProcedureReturn RGBA(Byte1, Byte2, Byte3, Byte4)
EndProcedure

Procedure ConvertBufferToImage(*Buffer, BufferSize.q)
  Protected ImageHeader.TImageHeader\Size = BufferSize
  
  ;each three bytes can be stored in one pixel
  Protected NumPixels.q = Round(BufferSize / 4, #PB_Round_Up)
  ;more pixels to store the orignal file size at the beggining
  NumPixels + #ImageHeaderSize / 4
  
  Protected SquareRootNumPixels.f = Sqr(NumPixels)
  Protected ImageWidth.q = Round(SquareRootNumPixels, #PB_Round_Up)
  Protected ImageHeight.q = ImageWidth
  
  Protected Image = CreateImage(#PB_Any, ImageWidth, ImageHeight, 32, #PB_Image_Transparent)
  If Image = 0
    ProcedureReturn #False
  EndIf
  
  Protected BufferOfsset.q;offset so we can read *buffer byte by byte
  
  StartDrawing(ImageOutput(Image))
  DrawingMode(#PB_2DDrawing_AllChannels)
  Protected ImageX, ImageY
  Protected Color.q
  
  ;plot 2 pixels (8 bytes) to the beggining of the image
  ;that will contain the input file size
  
  ;after saving the imageheader, ByteOffset will store how many
  ;bytes we already saved on the image
  Protected ByteOffset = 0
  Dim BytesArrayImageHeader.a(#ImageHeaderSize - 1)
  ConvertImageHeaderToBytesArray(@ImageHeader, BytesArrayImageHeader())
  For ByteOffset = 0 To (#ImageHeaderSize - 1) Step 4
    Protected Byte1.a, Byte2.a, Byte3.a, Byte4.a
    ;reads bytes from the imageheader, 3 bytes at a time
    Byte1 = BytesArrayImageHeader(ByteOffset + 0)
    Byte2 = BytesArrayImageHeader(ByteOffset + 1)
    Byte3 = BytesArrayImageHeader(ByteOffset + 2)
    Byte4 = BytesArrayImageHeader(ByteOffset + 3)
    Color = ConvertBytesToColor(Byte1, Byte2, Byte3, Byte4)
    ;calculate the position on the image using the byteoffset
    ImageX = (ByteOffset / 4) % ImageWidth
    ImageY = (ByteOffset/ 4) / ImageHeight
    Plot(ImageX, ImageY, Color)
  Next
  
  ;now we'll save the bytes inside the *buffer on the image
  ;the same as above: 4 bytes per pixel
  
  ;CurrentNumBytes stores how many bytes we read from the buffer
  ;when it reaches 4 we convert it to a pixel and plot on the image
  ;CurrentBytes store the actual bytes values
  Protected CurrentNumBytes.a = 0, Dim CurrentBytes.a(3)
  
  For BufferOfsset = 0 To BufferSize - 1
    Protected *CurrentByte.Ascii = *Buffer + BufferOfsset
    CurrentNumBytes + 1
    CurrentBytes(CurrentNumBytes - 1) = *CurrentByte\a
    If CurrentNumBytes < 4
      ;we still don't have 4 bytes, so we keep reading them from *Buffer
      Continue
    Else
      ;got the 4 bytes to generate a color so we can save it as pixel on the image
      CurrentNumBytes = 0
      Color = ConvertBytesToColor(CurrentBytes(0), CurrentBytes(1), CurrentBytes(2), CurrentBytes(3))
      ImageX = ((ByteOffset + BufferOfsset) / 4) % ImageWidth
      ImageY = ((ByteOffset + BufferOfsset) / 4) / ImageHeight
      Plot(ImageX, ImageY, Color)
      CurrentBytes(0) = 0 : CurrentBytes(1) = 0 : CurrentBytes(2) = 0 : CurrentBytes(3) = 0
    EndIf
  Next
  
  ;save the pending bytes on the image
  If CurrentNumBytes <> 0
    ;the number of bytes in *Buffer might not be divisible by 4, so 
    ;we are left with one, two or three bytes to save 
    BufferOfsset + 1
    Select CurrentNumBytes
      Case 1:
        ;only 1 byte left
        Color = ConvertBytesToColor(CurrentBytes(0))
      Case 2:
        ;2 bytes left
        Color = ConvertBytesToColor(CurrentBytes(0), CurrentBytes(1))
      Case 3:
        ;3 bytes left
        Color = ConvertBytesToColor(CurrentBytes(0), CurrentBytes(1), CurrentBytes(3))
    EndSelect
    ImageX = ((ByteOffset + BufferOfsset) / 4) % ImageWidth
    ImageY = ((ByteOffset + BufferOfsset) / 4) / ImageHeight
    Plot(ImageX, ImageY, Color)
  EndIf
  StopDrawing()
  
  ProcedureReturn Image
EndProcedure

Procedure ExtractImageHeader(ImageNum.i, *ImageHeader.TImageHeader)
  Protected ImageWidth, ImageHeight
  ImageWidth = ImageWidth(ImageNum)
  ImageHeight = ImageHeight(ImageNum)
  
  ;Bytes stores the bytes for the image header, which we'll copy to *ImageHeader
  ;so we can read the size
  Dim Bytes.a(#ImageHeaderSize - 1)
  StartDrawing(ImageOutput(ImageNum))
  DrawingMode(#PB_2DDrawing_AllChannels)
  Protected CurrentByte
  For CurrentByte = 0 To #ImageHeaderSize - 1 Step 4;4 bytes per pixel
    ;calculate the positions of the bytes in the bytes array
    Protected PosByte1.a = CurrentByte + 0
    Protected PosByte2.a = CurrentByte + 1
    Protected PosByte3.a = CurrentByte + 2
    Protected PosByte4.a = CurrentByte + 3
    
    ;using the byte we get the pixel position
    Protected CurrentX = (PosByte1 / 4) % ImageWidth
    Protected CurrentY = (PosByte1 / 4) / ImageHeight
    
    ;read the pixel value and extracts the 4 bytes (red, green, blue and alpha)
    Protected Color = Point(CurrentX, CurrentY)
    Bytes(PosByte1) = Red(Color)
    Bytes(PosByte2) = Green(Color)
    Bytes(PosByte3) = Blue(Color)
    Bytes(PosByte4) = Alpha(Color)
    
    
  Next
  
  ;copies the bytes to the *imageheader structure so we can read the size
  CopyMemory(@Bytes(0), *ImageHeader, #ImageHeaderSize)
  
  StopDrawing()
EndProcedure

Procedure.i ConvertImageToBuffer(ImageNum.i, BufferSize.q)
  Protected *Buffer = AllocateMemory(BufferSize, #PB_Memory_NoClear)
  If *Buffer = 0
    ProcedureReturn #Null
  EndIf
  
  Protected ImageWidth, ImageHeight
  ImageWidth = ImageWidth(ImageNum)
  ImageHeight = ImageHeight(ImageNum)
  Protected *BufferPosition = 0
  Protected ImageX, ImageY, StartImageY, StartImageX
  ;the first 8 bytes or 2 pixels are the original file size
  ;so we skip them
  StartImageY = (#ImageHeaderSize / 4) / ImageHeight
  StartImageX = (#ImageHeaderSize / 4) % ImageWidth
  ;NumPixels is the number of pixels we need to read from the image
  ;to get all bytes from the original file.
  ;PixelsRead is the number of pixels we already read
  Protected NumPixels = Round(BufferSize / 4, #PB_Round_Up), PixelsRead = 0
  StartDrawing(ImageOutput(ImageNum))
  DrawingMode(#PB_2DDrawing_AllChannels)
  For ImageY = StartImageY To ImageHeight - 1
    For ImageX = StartImageX To ImageWidth - 1
      ;reads the bytes from pixel and copy to buffer
      Protected Dim Bytes.a(3)
      Protected Color = Point(ImageX, ImageY)
      Bytes(0) = Red(Color)
      Bytes(1) = Green(Color)
      Bytes(2) = Blue(Color)
      Bytes(3) = Alpha(Color)
      
      CopyMemory(@Bytes(0), *Buffer + *BufferPosition, 4)
      *BufferPosition + 4
      PixelsRead + 1
      
      
      If PixelsRead = NumPixels
        Break
      EndIf
    Next ImageX
    ;in the fist iteration we skipped the first 3 pixels
    ;now we can start from the fist column again to read the
    ;rest of the pixels
    StartImageX = 0
    If PixelsRead = NumPixels
      Break
    EndIf
  Next ImageY
  StopDrawing()
  
  ProcedureReturn *Buffer
  
  
EndProcedure

DisableExplicit