import { Injectable } from '@angular/core';
import { GoodReceiptEndPoint } from './good-receipt.endpoint';
import { GoodsReceipt } from './goods-receipt.model';
import { Observable, throwError } from 'rxjs';
import { map, catchError } from 'rxjs/operators';

@Injectable()
export class GoodReceiptService {

    public _Id: number = null;

    get Id(): number {
        return this._Id;
    }
    set Id(Id: number) {
        this._Id = Id;
    }

    constructor(public goodReceiptEndPoint: GoodReceiptEndPoint) {

    }

    public GetGoodReceiptList() {
        return this.goodReceiptEndPoint.GetGoodReceiptList()
            .pipe(map(res => { return res }));
    }

    public AddGoodReceipt(CurrentReceipt: GoodsReceipt) {
        return this.goodReceiptEndPoint.AddGoodReceipt(CurrentReceipt)
            .pipe(
                map(res => {
                    return res;
                }),
                catchError((e: any) => {
                    this.errorHandler(e);
                    return throwError(() => e);
                })
            );
    }

    public UpdateGoodReceipt(CurrentReceipt: GoodsReceipt) {
        return this.goodReceiptEndPoint.UpdateGoodReceipt(CurrentReceipt)
            .pipe(map(res => { return res }));
    }

    public GetGoodReceipt(id: number) {
        return this.goodReceiptEndPoint.GetGoodReceipt(id)
            .pipe(map(res => { return res }));
    }

    public GetVendorList() {
        return this.goodReceiptEndPoint.GetVendorList()
            .pipe(
                map(res => { return res }),
                catchError((e: any) => {
                    this.errorHandler(e);
                    return throwError(() => e);
                })
            );
    }
    //get Other Charges Details
    public getINVOtherChargesDetails() {
        return this.goodReceiptEndPoint.getINVOtherChargesDetails()
            .pipe(
                map(res => { return res }),
                catchError((e: any) => {
                    this.errorHandler(e);
                    return throwError(() => e);
                })
            );
    }

    errorHandler(error: any): void {
        console.log(error)
    }

    globalInvGoodReceipt: GoodsReceipt = new GoodsReceipt();
    public GetGlobalInvReceipt(): GoodsReceipt {
        return this.globalInvGoodReceipt;
    }

}
