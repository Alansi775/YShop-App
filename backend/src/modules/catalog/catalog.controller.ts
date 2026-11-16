import { Controller, Get, Header, Param, ParseIntPipe, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { Public } from '../../common/decorators/auth.decorators';
import { ProductQueryDto, StoreQueryDto } from './catalog.dto';
import { CatalogService } from './catalog.service';

/** Browsing is open to guests. Short cache: lists feel instant, edits show within a minute. */
@ApiTags('catalog')
@Public()
@Controller()
export class CatalogController {
  constructor(private readonly catalog: CatalogService) {}

  @Get('store-types') @Header('Cache-Control', 'public, max-age=60')
  storeTypes() {
    return this.catalog.storeTypes();
  }

  @Get('stores') @Header('Cache-Control', 'public, max-age=30')
  stores(@Query() q: StoreQueryDto) {
    return this.catalog.stores(q);
  }

  @Get('stores/:id') @Header('Cache-Control', 'public, max-age=30')
  store(@Param('id', ParseIntPipe) id: number) {
    return this.catalog.store(id);
  }

  @Get('products') @Header('Cache-Control', 'public, max-age=30')
  products(@Query() q: ProductQueryDto) {
    return this.catalog.products(q);
  }

  @Get('products/:id') @Header('Cache-Control', 'public, max-age=30')
  product(@Param('id', ParseIntPipe) id: number) {
    return this.catalog.product(id);
  }
}
