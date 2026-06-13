import { Input, Component} from '@angular/core';
import { LoadingScreenService } from './dsf-loading-screen.services';

@Component({
    selector: "dsf-loader",
    templateUrl:'./dsf-loader.html' ,
    styleUrls: ['../../../themes/theme-default/loading.component.css']
})

export class LoaderComponent {

    @Input("loadingScreen")
    public showLoading: boolean = false;
   
    constructor(public loadingScreenService: LoadingScreenService) {                  
           
    }  
    
  }
  