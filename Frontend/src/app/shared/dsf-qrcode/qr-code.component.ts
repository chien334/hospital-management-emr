import { Component, Input, OnChanges, SimpleChanges, ViewChild, ElementRef, AfterViewInit } from '@angular/core';
import * as QRCode from 'qrcode';

@Component({
  selector: 'qr-code',
  template: '<canvas #canvas></canvas>'
})
export class QRCodeComponent implements OnChanges, AfterViewInit {
  @Input() value: string = '';
  @Input() size: number = 150;
  @Input() padding: number = 2;
  @Input() backgroundAlpha: number = 1;

  @ViewChild('canvas', { static: true }) canvas!: ElementRef<HTMLCanvasElement>;

  ngOnChanges(changes: SimpleChanges): void {
    this.generateQRCode();
  }

  ngAfterViewInit(): void {
    this.generateQRCode();
  }

  generateQRCode(): void {
    if (this.canvas && this.canvas.nativeElement && this.value) {
      QRCode.toCanvas(this.canvas.nativeElement, this.value, {
        width: this.size,
        margin: this.padding
      }, (error) => {
        if (error) console.error('QR Code generation error:', error);
      });
    }
  }
}
