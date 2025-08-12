import { loadRemoteModule } from '@angular-architects/module-federation';
import { CommonModule } from '@angular/common';
import { Component, ViewChild, ViewContainerRef, OnInit, AfterViewInit } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatSidenavModule } from '@angular/material/sidenav';

@Component({
  standalone: true,
  selector: 'app-root',
  imports: [CommonModule, MatIconModule, MatButtonModule, MatSidenavModule],
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss',
})
export class AppComponent implements AfterViewInit {
  title = 'lgs-mfe-container';
  showCart = false;

  @ViewChild('catalogContent', { read: ViewContainerRef }) 
  catalogContent!: ViewContainerRef;

  @ViewChild('cartContent', { read: ViewContainerRef }) 
  cartContent!: ViewContainerRef;

  constructor() {
    console.log('AppComponent constructor');
  }

  async ngAfterViewInit() {
    // Carrega o catalog como página principal
    await this.loadCatalog();
  }

  async loadCatalog() {
    try {
      this.catalogContent?.clear();
      const module = await loadRemoteModule({
        type: 'module',
        remoteEntry: 'http://localhost:4201/remoteEntry.js',
        exposedModule: 'lgs-mfe-catalog/Component',
      });
      this.catalogContent?.createComponent(module.AppComponent);
    } catch (error) {
      console.error('Erro ao carregar catalog:', error);
    }
  }

  async toggleCart() {
    this.showCart = !this.showCart;
    
    if (this.showCart) {
      try {
        this.cartContent?.clear();
        const module = await loadRemoteModule({
          type: 'module',
          remoteEntry: 'http://localhost:4202/remoteEntry.js',
          exposedModule: 'lgs-mfe-cart/Component',
        });
        this.cartContent?.createComponent(module.AppComponent);
      } catch (error) {
        console.error('Erro ao carregar cart:', error);
      }
    }
  }
}
