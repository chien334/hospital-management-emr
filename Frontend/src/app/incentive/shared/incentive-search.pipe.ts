import { Pipe, PipeTransform } from '@angular/core';

@Pipe({ name: 'incentiveSearch' })
export class IncentiveSearchPipe implements PipeTransform {
  transform(items: any[], searchText: string): any[] {
    if (!items) return [];
    if (!searchText) return items;
    searchText = searchText.toLowerCase();
    return items.filter(it => {
      for (const key in it) {
        if (it[key] !== null && it[key] !== undefined && it[key].toString().toLowerCase().includes(searchText)) {
          return true;
        }
      }
      return false;
    });
  }
}
