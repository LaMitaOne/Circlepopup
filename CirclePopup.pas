unit CirclePopup;

interface

uses
  Forms, Graphics, Controls, Math, Classes, Messages, Windows;

type
  // Event type for the segment click event
  TCirclePopupClickEvent = procedure(Sender: TObject; SegmentIndex: Integer) of object;

  // A standalone form for the popup (without .dfm file)
  TCirclePopupForm = class(TComponent)
  private
    FSegmentCount: Integer;
    FSegmentColor: TColor;
    FHoverColor: TColor;
    FBorderColor: TColor;
    FInnerRadius: Integer;
    FOuterRadius: Integer;
    FCenterX, FCenterY: Integer;
    FAngleStep: Double;
    FMouseSegment: Integer;
    FOldWndProc: TWndMethod;
    FOnSegmentClick: TCirclePopupClickEvent;
    FSegmentText: array of string;  // Dynamic array for segment text
    FTextColor: TColor;            // Single text color for all segments
    FPopupForm: TForm;
    FAlphaBlendValue: Byte;        // Stores current alpha value
    
    procedure SetOnSegmentClick(const Value: TCirclePopupClickEvent);
    function GetSegmentFromMouse(X, Y: Integer): Integer;
    procedure DrawSegmentText(i: Integer; AngleStart, AngleEnd: Double);
    procedure CreatePopupForm(StartX, StartY: Integer);
    procedure ApplyAlphaBlend;
    function GetAngle(X, Y: Integer): Double;
    procedure PopupFormWndProc(var Msg: TMessage);
  public
    constructor CreatePopup(StartX, StartY: Integer; InnerRadius, OuterRadius: Integer;
      SegmentColor, HoverColor, BorderColor: TColor; SegmentCount: Integer;
      SegmentText: array of string; TextColor: TColor;
      OnSegmentClick: TCirclePopupClickEvent);
    procedure PopupFormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PopupFormClick(Sender: TObject);
    procedure ShowPopup;
    procedure PaintPopupForm(Sender: TObject);
    procedure FadeOutPopup;
    procedure PopupFormClose(Sender: TObject; var Action: TCloseAction);  // New method here
  published
    property OnSegmentClick: TCirclePopupClickEvent read FOnSegmentClick write SetOnSegmentClick;
  end;

procedure ShowCirclePopup(StartX, StartY: Integer; InnerRadius, OuterRadius: Integer;
  SegmentColor, HoverColor, BorderColor: TColor; SegmentCount: Integer;
  SegmentText: array of string; TextColor: TColor;
  OnSegmentClick: TCirclePopupClickEvent);

implementation

// Set the OnSegmentClick event
procedure TCirclePopupForm.SetOnSegmentClick(const Value: TCirclePopupClickEvent);
begin
  FOnSegmentClick := Value;
end;

// Create the popup
constructor TCirclePopupForm.CreatePopup(StartX, StartY: Integer; InnerRadius, OuterRadius: Integer;
  SegmentColor, HoverColor, BorderColor: TColor; SegmentCount: Integer;
  SegmentText: array of string; TextColor: TColor;
  OnSegmentClick: TCirclePopupClickEvent);
var
  i: Integer;
begin
  inherited Create(nil);  // Create component without form base
  FSegmentColor := SegmentColor;
  FHoverColor := HoverColor;
  FBorderColor := BorderColor;
  FInnerRadius := InnerRadius;
  FOuterRadius := OuterRadius;
  FCenterX := OuterRadius;
  FCenterY := OuterRadius;
  FSegmentCount := SegmentCount;
  FAngleStep := 360 / SegmentCount;

  // Initialize and fill dynamic array for SegmentText
  SetLength(FSegmentText, Length(SegmentText));
  for i := 0 to High(SegmentText) do
    FSegmentText[i] := SegmentText[i];

  FTextColor := TextColor;
  FOnSegmentClick := OnSegmentClick;

  // Create popup form
  CreatePopupForm(StartX, StartY);

  FAlphaBlendValue := 200;
end;

// Create the popup form
procedure TCirclePopupForm.CreatePopupForm(StartX, StartY: Integer);
begin
  // Create popup as TForm
  FPopupForm := TForm.Create(nil);
  FPopupForm.FormStyle := fsStayOnTop;
  FPopupForm.BorderStyle := bsNone;
  FPopupForm.AlphaBlend := True;

  FOldWndProc := FPopupForm.WindowProc;
  FPopupForm.WindowProc := PopupFormWndProc;
  FPopupForm.Position := poDesigned;
  FPopupForm.AlphaBlendValue := 0;
  FPopupForm.Color := clFuchsia;  // Set background color to transparent
  FPopupForm.Cursor := crHandpoint;
  FPopupForm.TransparentColor := True;
  FPopupForm.TransparentColorValue := clFuchsia;  // Set transparent color value
  FPopupForm.Width := FOuterRadius * 2;
  FPopupForm.Height := FOuterRadius * 2;
  FPopupForm.Left := StartX - FOuterRadius;
  FPopupForm.Top := StartY - FOuterRadius;

  // Assign events
  FPopupForm.OnMouseMove := PopupFormMouseMove;
  FPopupForm.OnClick := PopupFormClick;
  FPopupForm.OnPaint := PaintPopupForm;  // Set paint event
  FPopupForm.OnClose := PopupFormClose;    // Close with fade-out effect
end;

procedure TCirclePopupForm.PopupFormClose(Sender: TObject; var Action: TCloseAction);
begin
  FadeOutPopup;
  Action := caFree;  // Close form after fade-out
end;

// Draw text for each segment
procedure TCirclePopupForm.DrawSegmentText(i: Integer; AngleStart, AngleEnd: Double);
var
  TextWidth, TextHeight: Integer;
  TextX, TextY: Integer;
  MidAngle: Double;
  TextToDraw: string;
begin
  if Length(FSegmentText) > i then
    TextToDraw := FSegmentText[i]
  else
    TextToDraw := '';

  MidAngle := (AngleStart + AngleEnd) / 2;
  TextX := Round(FCenterX + (FInnerRadius + (FOuterRadius - FInnerRadius) / 2) * Cos(DegToRad(MidAngle)));
  TextY := Round(FCenterY - (FInnerRadius + (FOuterRadius - FInnerRadius) / 2) * Sin(DegToRad(MidAngle)));

  FPopupForm.Canvas.Font.Size := 7;
  if i = FMouseSegment then
    FPopupForm.Canvas.Font.Color := FHoverColor*-1 //clBlack//FHoverColor // Optional: different text color on mouseover
  else
    FPopupForm.Canvas.Font.Color := FTextColor;

  TextWidth := FPopupForm.Canvas.TextWidth(TextToDraw);
  TextHeight := FPopupForm.Canvas.TextHeight(TextToDraw);

  FPopupForm.Canvas.TextOut(TextX - TextWidth div 2, TextY - TextHeight div 2, TextToDraw);
end;

procedure TCirclePopupForm.PopupFormWndProc(var Msg: TMessage);
begin
  if Msg.Msg = WM_MOUSELEAVE then
  begin
    FMouseSegment := -1;
  end
  else if (Msg.Msg = WM_ACTIVATE) and (Msg.wParam = WA_INACTIVE) then
  begin
    FadeOutPopup;
  end;
  if Assigned(FOldWndProc) then
    FOldWndProc(Msg);
end;

// Paint event for the popup
procedure TCirclePopupForm.PaintPopupForm(Sender: TObject);
var
  AngleStart, AngleEnd: Double;
  i: Integer;
  SegmentAngle: Double;
begin
  // Gap in degrees (1 pixel gap)
  SegmentAngle := FAngleStep - 1 / FOuterRadius * 360;

  for i := 0 to FSegmentCount - 1 do
  begin
    AngleStart := i * FAngleStep;
    AngleEnd := AngleStart + SegmentAngle;

    // Draw segment
    if i = FMouseSegment then
      FPopupForm.Canvas.Brush.Color := FHoverColor // Mouseover color
    else
      FPopupForm.Canvas.Brush.Color := FSegmentColor;

    FPopupForm.Canvas.Pen.Color := FBorderColor;
    FPopupForm.Canvas.Pen.Width := 1;
    FPopupForm.Canvas.Pie(FCenterX - FOuterRadius, FCenterY - FOuterRadius,
                          FCenterX + FOuterRadius, FCenterY + FOuterRadius,
                          Round(FCenterX + FOuterRadius * Cos(DegToRad(AngleStart))),
                          Round(FCenterY - FOuterRadius * Sin(DegToRad(AngleStart))),
                          Round(FCenterX + FOuterRadius * Cos(DegToRad(AngleEnd))),
                          Round(FCenterY - FOuterRadius * Sin(DegToRad(AngleEnd))));

    // Draw segment text
    DrawSegmentText(i, AngleStart, AngleEnd);
  end;

  // Draw inner circle (hole)
  FPopupForm.Canvas.Brush.Color := clFuchsia;
  FPopupForm.Canvas.Pen.Color := clFuchsia;
  FPopupForm.Canvas.Ellipse(FCenterX - FInnerRadius, FCenterY - FInnerRadius,
                            FCenterX + FInnerRadius, FCenterY + FInnerRadius);
end;

// Apply alpha blending for fade-in and fade-out effects
procedure TCirclePopupForm.ApplyAlphaBlend;
begin
  FPopupForm.AlphaBlendValue := FAlphaBlendValue;
end;

// Fade-out effect
procedure TCirclePopupForm.FadeOutPopup;
begin
  if not FPopupForm.Visible then exit;

  //FAlphaBlendValue := 255;
  repeat
    if FAlphaBlendValue > 4 then
    FAlphaBlendValue := FAlphaBlendValue - 3;
    ApplyAlphaBlend;
    Sleep(2);
    Application.ProcessMessages;
  until FAlphaBlendValue <= 10;
  FPopupForm.Hide;
  FPopupForm.Close;
end;

// MouseMove event for popup form
procedure TCirclePopupForm.PopupFormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  NewSegment: Integer;
begin
  NewSegment := GetSegmentFromMouse(X, Y);
  if FMouseSegment <> NewSegment then
  begin
    FMouseSegment := NewSegment;
    FPopupForm.Invalidate; // Redraw to update highlight
  end;
end;

// Popup click event
procedure TCirclePopupForm.PopupFormClick(Sender: TObject);
var
  MousePos: TPoint;
  Segment: Integer;
begin
  MousePos := Mouse.CursorPos;
  MousePos := FPopupForm.ScreenToClient(MousePos);
  Segment := GetSegmentFromMouse(MousePos.X, MousePos.Y);
  
  // Correction only for click
  Segment := FSegmentCount - 1 - Segment;
  
  if Assigned(FOnSegmentClick) then
    FOnSegmentClick(Sender, Segment);
  FadeOutPopup;
end;

// Determine segment based on mouse position
function TCirclePopupForm.GetAngle(X, Y: Integer): Double;
var
  DeltaX, DeltaY: Integer;
begin
  DeltaX := X - FCenterX;
  DeltaY := FCenterY - Y; // Reverse Y-axis (Delphi coordinates)
  
  Result := RadToDeg(ArcTan2(DeltaY, DeltaX));
  if Result < 0 then
    Result := Result + 360;
end;

// Show the popup
procedure TCirclePopupForm.ShowPopup;
begin
  FPopupForm.AlphaBlendValue := 220;
  FPopupForm.ShowModal;
end;

function TCirclePopupForm.GetSegmentFromMouse(X, Y: Integer): Integer;
var
  Angle: Double;
begin
  Angle := GetAngle(X, Y);
  // Shift angle by 90° if needed
  Angle := Angle + 20; // or -90, depending
  if Angle >= 360 then
    Angle := Angle - 360;
  
  Result := Floor(Angle / FAngleStep);
  if Result >= FSegmentCount then
    Result := FSegmentCount - 1;
  if Result < 0 then
    Result := 0;
end;

procedure ShowCirclePopup(StartX, StartY: Integer; InnerRadius, OuterRadius: Integer;
  SegmentColor, HoverColor, BorderColor: TColor; SegmentCount: Integer;
  SegmentText: array of string; TextColor: TColor;
  OnSegmentClick: TCirclePopupClickEvent);
var
  Popup: TCirclePopupForm;
begin
  Popup := TCirclePopupForm.CreatePopup(StartX, StartY, InnerRadius, OuterRadius,
    SegmentColor, HoverColor, BorderColor, SegmentCount, SegmentText, TextColor, OnSegmentClick);

  Popup.ShowPopup;
end;

end.