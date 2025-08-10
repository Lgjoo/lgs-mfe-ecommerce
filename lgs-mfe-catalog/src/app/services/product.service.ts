import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';

export interface Product {
  id: number;
  name: string;
  description: string;
  price: number;
  image: string;
  category: string;
  inStock: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class ProductService {
  private products: Product[] = [
    {
      id: 1,
      name: 'Smartphone Pro',
      description: 'Latest smartphone with amazing features',
      price: 999,
      image: '📱',
      category: 'Electronics',
      inStock: true
    },
    {
      id: 2,
      name: 'Laptop Ultra',
      description: 'High-performance laptop for professionals',
      price: 1499,
      image: '💻',
      category: 'Electronics',
      inStock: true
    },
    {
      id: 3,
      name: 'Wireless Headphones',
      description: 'Premium sound quality with noise cancellation',
      price: 299,
      image: '🎧',
      category: 'Audio',
      inStock: true
    },
    {
      id: 4,
      name: 'Smart Watch',
      description: 'Fitness tracking and health monitoring',
      price: 399,
      image: '⌚',
      category: 'Wearables',
      inStock: false
    },
    {
      id: 5,
      name: 'Gaming Console',
      description: 'Next-gen gaming experience',
      price: 499,
      image: '🎮',
      category: 'Gaming',
      inStock: true
    },
    {
      id: 6,
      name: 'Tablet Pro',
      description: 'Portable computing power',
      price: 799,
      image: '📱',
      category: 'Electronics',
      inStock: true
    }
  ];

  constructor() { }

  getProducts(): Observable<Product[]> {
    return of(this.products);
  }

  getProductById(id: number): Observable<Product | undefined> {
    const product = this.products.find(p => p.id === id);
    return of(product);
  }

  searchProducts(query: string): Observable<Product[]> {
    const filteredProducts = this.products.filter(product =>
      product.name.toLowerCase().includes(query.toLowerCase()) ||
      product.description.toLowerCase().includes(query.toLowerCase())
    );
    return of(filteredProducts);
  }
} 