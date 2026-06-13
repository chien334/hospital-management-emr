import { NgModule, ModuleWithProviders } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

import { DsfAutoCompleteComponent } from './dsf-auto-complete.component';
import { DsfAutoCompleteDirective } from './dsf-auto-complete.directive';
import { DsfAutoComplete } from './dsf-auto-complete';

@NgModule({
    imports: [CommonModule, FormsModule],
    declarations: [
        DsfAutoCompleteComponent,
        DsfAutoCompleteDirective
    ],
    exports: [
        DsfAutoCompleteComponent,
        DsfAutoCompleteDirective
    ]
})
export class DsfAutoCompleteModule {
  static forRoot(): ModuleWithProviders<DsfAutoCompleteModule> {
    return {
        ngModule: DsfAutoCompleteModule,
        providers: [DsfAutoComplete]
    };
}
}

