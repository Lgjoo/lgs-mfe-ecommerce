import { Routes } from '@angular/router';
import { loadRemoteModule } from '@angular-architects/module-federation';

export const routes: Routes = [
  {
    path: 'catalog',
    loadComponent: () => {
      console.log('Loading catalog component...');
      return loadRemoteModule({
        type: 'module',
        remoteEntry: 'http://localhost:4201/remoteEntry.js',
        exposedModule: 'lgs-mfe-catalog/Module',
      }).then(m => {
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
      return loadRemoteModule({
        type: 'module',
        remoteEntry: 'http://localhost:4202/remoteEntry.js',
        exposedModule: 'lgs-mfe-cart/Module',
      }).then(m => {
        console.log('Cart module loaded:', m);
        return m.AppComponent;
      }).catch(err => {
        console.error('Failed to load cart module:', err);
        throw err;
      });
    }
  },
];
