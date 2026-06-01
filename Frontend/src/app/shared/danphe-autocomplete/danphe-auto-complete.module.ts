import { NgModule, ModuleWithProviders } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

import { DanpheAutoCompleteComponent } from './danphe-auto-complete.component';
import { DanpheAutoCompleteDirective } from './danphe-auto-complete.directive';
import { DanpheAutoComplete } from './danphe-auto-complete';

@NgModule({
    imports: [CommonModule, FormsModule],
    declarations: [
        DanpheAutoCompleteComponent,
        DanpheAutoCompleteDirective
    ],
    exports: [
        DanpheAutoCompleteComponent,
        DanpheAutoCompleteDirective
    ]
})
export class DanpheAutoCompleteModule {
  static forRoot(): ModuleWithProviders<DanpheAutoCompleteModule> {
    return {
        ngModule: DanpheAutoCompleteModule,
        providers: [DanpheAutoComplete]
    };
}
}

