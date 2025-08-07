import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: 'catalog',
    loadComponent: () => {
      console.log('Loading catalog component...');
      return import('lgs-mfe-catalog/Module').then(m => {
        console.log('Catalog module loaded:', m);
        return m.AppComponent;
      }).catch(err => {
        console.error('Failed to load catalog module:', err);
        throw err;
      });
    }
  },
  {
    path: 'cart',
    loadComponent: () => {
      console.log('Loading cart component...');
      return import('lgs-mfe-cart/Module').then(m => {
        console.log('Cart module loaded:', m);
        return m.AppComponent;
      }).catch(err => {
        console.error('Failed to load cart module:', err);
        throw err;
      });
    }
  },
  {
    path: '',
    redirectTo: '/catalog',
    pathMatch: 'full'
  }
];
