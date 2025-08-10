import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ProductService, Product } from '../../services/product.service';

@Component({
  selector: 'app-product-list',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './product-list.component.html',
  styleUrls: ['./product-list.component.scss']
})
export class ProductListComponent implements OnInit {
  products: Product[] = [];
  filteredProducts: Product[] = [];
  searchQuery: string = '';
  loading: boolean = true;
  searchTimeout: any;

  constructor(private productService: ProductService) {}

  ngOnInit(): void {
    this.loadProducts();
  }

  loadProducts(): void {
    this.loading = true;
    this.productService.getProducts().subscribe({
      next: (products) => {
        this.products = products;
        this.filteredProducts = products;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading products:', error);
        this.loading = false;
      }
    });
  }

  onSearch(): void {
    // Clear previous timeout
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }

    // Debounce search to avoid too many API calls
    this.searchTimeout = setTimeout(() => {
      if (!this.searchQuery.trim()) {
        this.filteredProducts = this.products;
        return;
      }

      this.productService.searchProducts(this.searchQuery).subscribe({
        next: (products) => {
          this.filteredProducts = products;
        },
        error: (error) => {
          console.error('Error searching products:', error);
          this.filteredProducts = [];
        }
      });
    }, 300);
  }

  addToCart(product: Product): void {
    // TODO: Implement cart functionality
    console.log('Adding to cart:', product);
    
    // Add visual feedback
    const button = event?.target as HTMLButtonElement;
    if (button) {
      button.textContent = 'Added!';
      button.classList.add('bg-green-600');
      setTimeout(() => {
        button.textContent = product.inStock ? 'Add to Cart' : 'Out of Stock';
        button.classList.remove('bg-green-600');
      }, 1000);
    }
  }

  getStockStatus(product: Product): string {
    return product.inStock ? 'In Stock' : 'Out of Stock';
  }

  getStockStatusClass(product: Product): string {
    return product.inStock 
      ? 'text-green-600 bg-green-100' 
      : 'text-red-600 bg-red-100';
  }
} 