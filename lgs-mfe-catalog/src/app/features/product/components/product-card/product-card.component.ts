import { Component, Input } from '@angular/core';
import { IProduct } from '../../models/product.model';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';

@Component({
  selector: 'app-product-card',
  imports: [ MatButtonModule, MatCardModule ],
  templateUrl: './product-card.component.html',
  styleUrl: './product-card.component.scss',
  standalone: true,
})
export class ProductCardComponent {
  @Input() product!: IProduct;
}
