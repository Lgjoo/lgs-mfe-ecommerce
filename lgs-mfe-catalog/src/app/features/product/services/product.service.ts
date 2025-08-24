import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { IProduct } from '../models/product.model';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ProductService {
  private readonly STORE_API_ROOT_URL: string = 'https://fakestoreapi.com/';
  private readonly STORE_API_PRODUCT_LIST_URL: string = `${this.STORE_API_ROOT_URL}products`;

  constructor(private httpClient: HttpClient) { }

  getProducts(): Observable<IProduct[]> {
    return this.httpClient.get<IProduct[]>(this.STORE_API_PRODUCT_LIST_URL);
  }
}
