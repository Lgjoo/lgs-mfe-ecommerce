import { Component } from '@angular/core';
import { ProductListComponent } from './features/product/components/product-list/product-list.component';

@Component({
  standalone: true,
  selector: 'app-root',
  imports: [ProductListComponent],
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss',
})
export class AppComponent {}
