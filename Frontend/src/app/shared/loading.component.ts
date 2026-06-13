import { Component, Directive } from '@angular/core';
import { Input } from "@angular/core"
@Component({
    selector: "dsf-loading",
    template: `
   <div class="dsf-loading-image" [hidden]="!showLoading">
    <img style="margin-top: 60px;width: 120px; height: 120px;" [src]="pathToImage" />
    <p style="font-size: 24px;color: #fff;"><b>{{ 'NAVBAR.LOADING' | translate }}</b></p>
    </div>`,
    styleUrls: ['../../themes/theme-default/loading.component.css']
})
export class LoadingComponent {
    @Input("loading")
    public showLoading: boolean = false;
    pathToImage: string = "";

    constructor() {
        this.pathToImage = "../../../../themes/theme-default/images/loading.gif";
    }
 
}
