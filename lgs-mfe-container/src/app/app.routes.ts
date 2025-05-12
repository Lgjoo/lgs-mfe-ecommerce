import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: 'catalog',
    loadComponent: () => import('lgs-mfe-catalog/Module').then(m => m.LgsMfeCatalogComponent)
  },
  {
    path: 'cart',
    loadComponent: () => import('lgs-mfe-cart/Module').then(m => m.LgsMfeCartComponent)
  }
];
