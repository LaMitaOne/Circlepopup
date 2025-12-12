unit Unit9;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, circlepopup;

type
  TForm9 = class(TForm)
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Private-Deklarationen }
    procedure HandleSegmentClick(Sender: TObject; SegmentIndex: Integer);
  public
    { Public-Deklarationen }
  end;

var
  Form9: TForm9;

implementation

{$R *.dfm}

procedure TForm9.HandleSegmentClick(Sender: TObject; SegmentIndex: Integer);
begin
   Showmessage('clicked - ' + inttostr(Segmentindex));
end;

procedure TForm9.Button1Click(Sender: TObject);
begin
    ShowCirclePopup(
      Mouse.CursorPos.X,
      // X-Position
      Mouse.CursorPos.Y ,
      // Y-Position
      20, // inner circle
      60, // outer circle
      clBlack, // back color
      clAqua, // hover color
      $00333300, // bordercolor
      6, // segments count
      ['10%', '30%', '50%', '70%', '90%', '100%'], // Segment-Text
      clGray, // Textcolor
      HandleSegmentClick);
end;

end.
