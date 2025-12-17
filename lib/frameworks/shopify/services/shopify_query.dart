/// Maximum width of an image is 5760px
const _imageWidth = 700;

/// Maximum height of an image is 5760px
const _imageHeight = 1000;

const _scale = 1;

class ShopifyQuery {
  static String getCollections = '''
    query(\$cursor: String
    \$pageSize: Int
    \$langCode: LanguageCode
    \$countryCode: CountryCode
    ) @inContext(language: \$langCode, country: \$countryCode) {
        collections(first: \$pageSize, after: \$cursor) {
          pageInfo {
            hasNextPage
            hasPreviousPage
          }
          edges {
            cursor
            node {
              ...collectionInformation
            }
          }
        }
    }
    $fragmentCollection
    ''';

  static String getProducts = '''
    query(
    \$cursor: String
    \$reverse: Boolean
    \$sortKey: ProductSortKeys
    \$pageSize: Int
    \$langCode: LanguageCode
    \$countryCode: CountryCode
    ) @inContext(language: \$langCode, country: \$countryCode) {
      products(first: \$pageSize, after: \$cursor, sortKey: \$sortKey, reverse: \$reverse) {
        pageInfo {
          hasNextPage
          hasPreviousPage
        }
        edges {
          cursor
          node {
            ...productInformation
          }
        }
      }
    }
    $fragmentProduct
  ''';

  static String getProductsByTag = '''
    query(
      \$pageSize: Int
      \$query: String
      \$langCode: LanguageCode
      \$countryCode: CountryCode
      \$cursor: String
    ) @inContext(language: \$langCode, country: \$countryCode) {
      products(first: \$pageSize , query:\$query, after: \$cursor ){
        pageInfo{
          hasNextPage
          hasPreviousPage
        }
        edges{
          cursor
          node{
            ...productInformation
          }
        }
      }
    }
    $fragmentProduct
  ''';

  static String getProductByName = '''
    query(
    \$cursor: String
    \$pageSize: Int
    \$query: String
    \$reverse: Boolean
    \$sortKey: ProductSortKeys
    \$langCode: LanguageCode
    \$countryCode: CountryCode
    ) @inContext(language: \$langCode, country: \$countryCode) {
        products(first: \$pageSize, after: \$cursor, query: \$query, sortKey: \$sortKey, reverse: \$reverse) {
          pageInfo {
            hasNextPage
            hasPreviousPage
          }
          edges {
            cursor
            node {
              ...productInformation
            }
          }
        }
    }
    $fragmentProduct
  ''';

  static String getProductById = '''
   query(
   \$id: ID!
   \$langCode: LanguageCode
   \$countryCode: CountryCode
   ) @inContext(language: \$langCode, country: \$countryCode) {
      node(id: \$id) {
      ...on Product {
        ...productInformation
       }
     }
   }
   $fragmentProduct
  ''';

  // static String getRelativeProducts = '''
  //   query(\$query: String, \$pageSize: Int) {
  //     shop {
  //       products(first: \$pageSize, query: \$query, sortKey: PRODUCT_TYPE) {
  //         pageInfo {
  //           hasNextPage
  //           hasPreviousPage
  //         }
  //         edges {
  //           cursor
  //           node {
  //             ...productInformation
  //           }
  //         }
  //       }
  //     }
  //   }
  //   $fragmentProduct
  // ''';

  static String getProductByCollection = '''
    query(
    \$categoryId: ID!
    \$pageSize: Int
    \$cursor: String
    \$reverse: Boolean
    \$sortKey: ProductCollectionSortKeys
    \$langCode: LanguageCode
    \$countryCode: CountryCode
    ) @inContext(language: \$langCode, country: \$countryCode) {
      node(id: \$categoryId) {
        id
        ... on Collection {
          title
          products(first: \$pageSize, after: \$cursor, sortKey: \$sortKey, reverse: \$reverse) {
            pageInfo {
              hasNextPage
              hasPreviousPage
            }
            edges {
              cursor
              node {
                ...productInformation
              }
            }
          }
        }
      }
    }
    $fragmentProduct
  ''';

  static String updateCheckoutAttribute = '''
    mutation checkoutAttributesUpdateV2(
    \$checkoutId: ID! 
    \$input: CheckoutAttributesUpdateV2Input!
    \$langCode: LanguageCode
    \$countryCode: CountryCode
    ) @inContext(language: \$langCode, country: \$countryCode) {
    checkoutAttributesUpdateV2(checkoutId: \$checkoutId, input: \$input) {
        checkout {
          id
        }
        checkoutUserErrors {
          code
          field
          message
        }
      }
    }
  ''';

  // static String updateCheckoutEmail = '''
  //   mutation checkoutAttributesUpdateV2(
  //   \$checkoutId: ID!
  //   \$email: String!
  //   \$langCode: LanguageCode
  //   \$countryCode: CountryCode
  //   ) @inContext(language: \$langCode, country: \$countryCode) {
  //   checkoutEmailUpdateV2(checkoutId: \$checkoutId, email: \$email) {
  //       checkout {
  //         id
  //       }
  //       checkoutUserErrors {
  //         code
  //         field
  //         message
  //       }
  //     }
  //   }
  // ''';

  static String createCustomer = '''
    mutation customerCreate(\$input: CustomerCreateInput!) {
      customerCreate(input: \$input) {
        userErrors {
          field
          message
        }
        customer {
          id
          email
          firstName
          lastName
          phone
        }
      }
    }
  ''';

  static String customerUpdate = '''
    mutation customerUpdate(\$customerAccessToken: String!, \$customer: CustomerUpdateInput!) {
    customerUpdate(customerAccessToken: \$customerAccessToken, customer: \$customer) {
      customer {
        ...userInformation
      }
      customerAccessToken {
        accessToken
        expiresAt
      }
      customerUserErrors {
        code
        field
        message
      }
    }
  }
  $fragmentUser
  ''';

  static String createCustomerToken = '''
    mutation customerAccessTokenCreate(\$input: CustomerAccessTokenCreateInput!) {
    customerAccessTokenCreate(input: \$input) {
      userErrors {
        field
        message
      }
      customerAccessToken {
        accessToken
        expiresAt
      }
    }
  }
  ''';

  static String renewCustomerToken = '''
    mutation customerAccessTokenRenew(\$customerAccessToken: String!) {
      customerAccessTokenRenew(customerAccessToken: \$customerAccessToken) {
        userErrors {
          field
          message
        }
        customerAccessToken {
          accessToken
          expiresAt
        }
      }
    }
  ''';

  static String getCustomerInfo = '''
    query(\$accessToken: String!) {
      customer(customerAccessToken: \$accessToken) {
        id
        email
        createdAt
        displayName
        phone
        firstName
        lastName
        defaultAddress {
          id
          firstName
          lastName
          company
          address1
          address2
          city
          zip
          phone
          name
          latitude
          longitude
          province
          country
          countryCode
          countryCodeV2
        }
        addresses(first: 50) {
          pageInfo {
            hasNextPage
            hasPreviousPage
          }
          edges {
            node {
              id
              firstName
              lastName
              company
              address1
              address2
              city
              zip
              phone
              name
              latitude
              longitude
              province
              country
              countryCodeV2
            }
          }
        }
      }
    }
  ''';

  static String getPaymentSettings = '''
    query {
      shop {
        paymentSettings {
          cardVaultUrl
          acceptedCardBrands
          countryCode
          currencyCode
          shopifyPaymentsAccountId
          supportedDigitalWallets
        }
      }
    }
  ''';

  static String getOrder = '''
    query(\$cursor: String, \$pageSize: Int, \$customerAccessToken: String!) {
      customer(customerAccessToken: \$customerAccessToken) {
        orders(first: \$pageSize, after: \$cursor, reverse: true) {
          pageInfo {
            hasNextPage
            hasPreviousPage
          }
          edges {
            cursor
            node {
              ...orderInformation
            }
          }
        }
      }
    }
    $fragmentOrder
  ''';

  static String getArticle = '''
    query(
    \$cursor: String
    \$pageSize: Int
    \$langCode: LanguageCode
    ) @inContext(language: \$langCode) {
        articles(
          first: \$pageSize 
          after: \$cursor
          sortKey: PUBLISHED_AT 
          reverse: true
          ) {
            pageInfo {
              hasNextPage
              hasPreviousPage
            }
            edges {
              cursor
              node {
                onlineStoreUrl
                title
                excerpt
                authorV2 {
                  name
                }
                id
                content
                contentHtml
                image {
                  ...imageInformation
                }
                publishedAt
              }
            }
          }
    }
    $fragmentImage
  ''';

  static String resetPassword = '''
    mutation customerRecover(\$email: String!) {
    customerRecover(email: \$email) {
      customerUserErrors {
        code
        field
        message
      }
    }
}
  ''';

  static String getProductByHandle = '''
   query (\$handle: String!) {
      productByHandle(handle: \$handle) {
        ...productInformation
      }
   }
   $fragmentProduct
''';

  static String deleteToken = '''
    mutation customerAccessTokenDelete(\$customerAccessToken: String!) {
      customerAccessTokenDelete(customerAccessToken: \$customerAccessToken) {
        deletedAccessToken
        deletedCustomerAccessTokenId
        userErrors {
          field
          message
        }
      }
    }
  ''';

  // Shopify Storefront API Customer Address Mutations
  static String customerAddressCreate = '''
    mutation customerAddressCreate(\$customerAccessToken: String!, \$address: MailingAddressInput!) {
      customerAddressCreate(customerAccessToken: \$customerAccessToken, address: \$address) {
        customerAddress {
          id
          address1
          address2
          city
          company
          country
          firstName
          lastName
          phone
          province
          zip
        }
        customerUserErrors {
          code
          field
          message
        }
      }
    }
  ''';

  static String customerAddressUpdate = '''
    mutation customerAddressUpdate(\$customerAccessToken: String!, \$id: ID!, \$address: MailingAddressInput!) {
      customerAddressUpdate(customerAccessToken: \$customerAccessToken, id: \$id, address: \$address) {
        customerAddress {
          id
          address1
          address2
          city
          company
          country
          firstName
          lastName
          phone
          province
          zip
        }
        customerUserErrors {
          code
          field
          message
        }
      }
    }
  ''';

  static String customerAddressDelete = '''
    mutation customerAddressDelete(\$customerAccessToken: String!, \$id: ID!) {
      customerAddressDelete(customerAccessToken: \$customerAccessToken, id: \$id) {
        deletedCustomerAddressId
        customerUserErrors {
          code
          field
          message
        }
      }
    }
  ''';

  static String customerDefaultAddressUpdate = '''
    mutation customerDefaultAddressUpdate(\$customerAccessToken: String!, \$addressId: ID!) {
      customerDefaultAddressUpdate(customerAccessToken: \$customerAccessToken, addressId: \$addressId) {
        customer {
          id
          defaultAddress {
            id
          }
        }
        customerUserErrors {
          code
          field
          message
        }
      }
    }
  ''';

  static String getArticleByHandle = '''
    query(\$blogHandle: String!, \$articleHandle: String!) {
      blog(handle: \$blogHandle) {
        articleByHandle(handle: \$articleHandle) {
          onlineStoreUrl
          title
          excerpt
          authorV2 {
            name
          }
          id
          content
          contentHtml
          image {
            ...imageInformation
          }
          publishedAt
        }
      }
    }
    $fragmentImage
  ''';

  static String cartPrepareForCompletion = '''
    mutation CartPrepareForCompletion(\$cartId: ID!) {
      cartPrepareForCompletion(cartId: \$cartId) {
        result {
          ... on CartStatusNotReady {
            carNotReady: cart {
              ...cartInformation
            }
            errors {
              code
              message
            }
          }
          ... on CartStatusReady {
            cartReady: cart {
              ...cartInformation
            }
          }
          ... on CartThrottled {
            pollAfter
          }
        }
        userErrors {
          code
          field
          message
        }
      }
    }
    $fragmentCart
''';

  static String cartPaymentUpdate = '''
    mutation CartPaymentUpdate(\$id: ID!, \$payment: CartPaymentInput!) {
      cartPaymentUpdate(cartId: \$id, payment: \$payment) {
        cart {
          ...cartInformation
        }
        userErrors {
          code
          field
          message
        }
        warnings {
          code
          message
          target
        }
      }
    }
    $fragmentCart
  ''';

  static String cartSubmitForCompletion = '''
    mutation CartSubmitForCompletion(\$cartId: ID!, \$attemptToken: String!) {
      cartSubmitForCompletion(cartId: \$cartId, attemptToken: \$attemptToken) {
        result {
          ... on SubmitFailed {
              checkoutUrl
              errors {
                code
                message
              }
          }
          ... on SubmitSuccess {
            redirectUrl
          }
          ... on SubmitThrottled {
            pollAfter
          }
        }
        userErrors {
          code
          field
          message
        }
      }
    }
  ''';

  static String fetchPayment = '''
    query(\$paymentId: ID!) {
        node(id: \$paymentId) {
            ... on Payment {
                id
                idempotencyKey
                nextActionUrl
                errorMessage
                ready
                test
                amount {
                    amount
                }
                checkout {
                  order {
                     ...orderInformation
                  }
                }
                transaction {
                    amount {
                        amount
                        currencyCode
                    }
                    statusV2
                    test
                }
                errorMessage
            }
        }
    }
    $fragmentOrder
  ''';

  static String getCollectionByHandle = '''
    query(
    \$handle: String
    \$langCode: LanguageCode
    ) @inContext(language: \$langCode) {
        collection(handle: \$handle) {
          ...collectionInformation
        }
    }
    $fragmentCollection
    ''';

  static String getCollectionById = '''
    query(\$id: ID, \$langCode: LanguageCode) @inContext(language: \$langCode) {
        collection(id: \$id) {
          ...collectionInformation
        }
    }
    $fragmentCollection
    ''';

  static String getAvailableCurrency = '''
    query {
      localization {
        availableCountries {
          currency {
            isoCode
            name
            symbol
          }
          isoCode
          name
          unitSystem
        }
        country {
          currency {
            isoCode
            name
            symbol
          }
          isoCode
          name
          unitSystem
        }
      }
    }
  ''';

  static const getProductVariant = '''
    query getProductVariant(
    \$id: ID!
    \$langCode: LanguageCode
    \$countryCode: CountryCode) 
    @inContext(language: \$langCode, country: \$countryCode) {
      node(id: \$id) {
          ... on ProductVariant {
              ...productVariantInformation
          }
      }
    }
    $fragmentProductVariant
  ''';

  static const cartCreate = '''
    mutation cartCreate(\$input: CartInput) {
      cartCreate(input: \$input ) {
        cart {
          ...cartInformation
        }  
        userErrors {
          code
          field
          message
        }
      } 
    }
    $fragmentCart
  ''';

  static const cartUpdate = '''
    mutation cartCreate(\$input: CartInput) {
      cartCreate(input: \$input ) {
        cart {
          ...cartInformation
        }  
        userErrors {
          code
          field
          message
        }
      } 
    }
    $fragmentCart
  ''';

  static const cartBuyerIdentifyUpdate = '''
    mutation cartBuyerIdentityUpdate(
    \$buyerIdentity: CartBuyerIdentityInput!
    \$cartId: ID!
    ) {
      cartBuyerIdentityUpdate(
        buyerIdentity: \$buyerIdentity
        cartId: \$cartId
      ) {
        cart {
          ...cartInformation
        }
        userErrors {
          field
          message
        }
      }
    }
    $fragmentCart
  ''';

  static const cartSelectedDeliveryOptionsUpdate = '''
    mutation cartSelectedDeliveryOptionsUpdate(
      \$cartId: ID!
      \$selectedDeliveryOptions: [CartSelectedDeliveryOptionInput!]!
    ) {
      cartSelectedDeliveryOptionsUpdate(
        cartId: \$cartId
        selectedDeliveryOptions: \$selectedDeliveryOptions
      ) {
        cart {
          ...cartInformation
        }
        userErrors {
          field
          message
        }
      }
    }    
    $fragmentCart
  ''';

  static const cartAttributesUpdate = '''
    mutation cartAttributesUpdate(\$attributes: [AttributeInput!]!, \$cartId: ID!) {
      cartAttributesUpdate(attributes: \$attributes, cartId: \$cartId) {
        cart {
          ...cartInformation
        }
        userErrors {
          field
          message
        }
      }
    }
    $fragmentCart
  ''';

  static const cartNoteUpdate = '''
    mutation cartNoteUpdate(\$cartId: ID!, \$note: String!) {
      cartNoteUpdate(cartId: \$cartId, note: \$note) {
        cart {
          ...cartInformation
        }
        userErrors {
          field
          message
        }
      }
    } 
    $fragmentCart
  ''';

  static const cartDiscountCodesUpdate = '''
    mutation cartDiscountCodesUpdate(\$cartId: ID!, \$discountCodes: [String!]!) {
      cartDiscountCodesUpdate(cartId: \$cartId, discountCodes: \$discountCodes) {
        cart {
          ...cartInformation
        }
        userErrors {
          field
          message
        }
      }
    }
    $fragmentCart
  ''';

  static const cartDeliveryAddressesUpdate = '''
    mutation cartDeliveryAddressesUpdate(\$cartId: ID!, \$addresses: [CartSelectableAddressUpdateInput!]!) {
      cartDeliveryAddressesUpdate(cartId: \$cartId, addresses: \$addresses) {
        cart {
          ...cartInformation
        }
        userErrors {
          field
          message
          code
        }
        warnings {
          message
          code
          target
        }
      }
    }
    $fragmentCart
  ''';

  static const cartDeliveryAddressesAdd = '''
    mutation cartDeliveryAddressesAdd(\$cartId: ID!, \$addresses: [CartSelectableAddressInput!]!) {
      cartDeliveryAddressesAdd(cartId: \$cartId, addresses: \$addresses) {
        cart {
          ...cartInformation
        }
        userErrors {
          field
          message
          code
        }
        warnings {
          message
          code
          target
        }
      }
    }
    $fragmentCart
  ''';

  static const fetchCart = '''
    query Cart(\$id: ID!) {
      cart(id: \$id) {
        ...cartInformation
      }
    }
    $fragmentCart
  ''';

  static const fragmentCart = '''
    fragment cartInformation on Cart {
      id
      checkoutUrl
      note
      totalQuantity
      deliveryGroups(first: 50) {
        nodes {
          id
          selectedDeliveryOption {
            ...cartDeliveryInformation
          }
          deliveryOptions {
            ...cartDeliveryInformation 
          }
        }
      }      
      buyerIdentity {
        countryCode
        email
        phone
        deliveryAddressPreferences {
          __typename
          ... on MailingAddress {
            address1
            address2
            city
            company
            country
            firstName
            lastName
            phone
            province
            zip
          }
        }        
        customer {
          ...userInformation
        }
      }
      attributes {
        key
        value
      }
      discountAllocations {
        ...cartDiscountAllocationInformation
      }
      discountCodes {
        applicable
        code
      }
      estimatedCost {
        checkoutChargeAmount {
          amount
          currencyCode
        }
        subtotalAmount {
          amount
          currencyCode
        }
        totalAmount {
          amount
          currencyCode
        }
        totalDutyAmount {
          amount
          currencyCode
        }
        totalTaxAmount {
          amount
          currencyCode
        }
      }
      lines(first: 100) {
        nodes {
          id
          quantity
          cost {
            totalAmount {
              amount
              currencyCode
            }
          }
          merchandise {
            ... on ProductVariant {
              availableForSale
              barcode
              currentlyNotInStock
              id
              quantityAvailable
              requiresShipping
              sku
              taxable
              title
              weight
              weightUnit
            }
          }
          ...on CartLine {
            discountAllocations {
              ...cartDiscountAllocationInformation
            }
          }
        }
      }
      cost {
        checkoutChargeAmount {
          amount
          currencyCode
        }
        subtotalAmount {
          amount
          currencyCode
        }
        totalAmount {
          amount
          currencyCode
        }
        totalDutyAmount {
          amount
          currencyCode
        }
        totalTaxAmount {
          amount
          currencyCode
        }
      }
    }
    $fragmentCartDelivery
    $fragmentCartDiscountAllocation
    $fragmentUser
  ''';

  static const fragmentCartDelivery = '''
    fragment cartDeliveryInformation on CartDeliveryOption {
      code
      deliveryMethodType
      description
      title
      handle
      estimatedCost {
        amount
        currencyCode
      }
    }
  ''';

  static const fragmentUser = '''
      fragment userInformation on Customer {
        id
        email
        createdAt
        displayName
        phone
        firstName
        lastName
        defaultAddress {
          address1
          address2
          city
          firstName
          id
          lastName
          zip
          phone
          name
          latitude
          longitude
          province
          country
          countryCode
        }
        addresses(first: 10) {
          pageInfo {
            hasNextPage
            hasPreviousPage
          }
          edges {
            node {
              address1
              address2
              city
              firstName
              id
              lastName
              zip
              phone
              name
              latitude
              longitude
              province
              country
              countryCode
            }
          }
        }
      }
  ''';

  static const fragmentProduct = '''
      fragment productInformation on Product {
          id
          title
          vendor
          description
          descriptionHtml
          totalInventory
          availableForSale
          productType
          onlineStoreUrl
          tags
          collections(first: 10) {
            edges {
              node {
                id
                title
                metafield(namespace: "custom", key: "collection_discount") {
                  value
                }
              }
            }
          }
          options {
            id
            name
            values
          }
          variants(first: 250) {
            pageInfo {
              hasNextPage
              hasPreviousPage
            }
            edges {
              node {
                ...productVariantInformation
              }
            }
          }
          images(first: 250) {
            edges {
              node {
                ...imageInformation
              }
            }
          }
          featuredImage {
            ...imageInformation
          }
          media(first: 250) {
            edges {
              node {
                ... on Video{
                  id
                  sources{
                    format
                    height
                    mimeType
                    url
                    width
                  }
                }
              }
            }
          }
        }
        $fragmentProductVariant
  ''';

  static const fragmentProductVariant = '''
    fragment productVariantInformation on ProductVariant {
      id
      title
      availableForSale
      quantityAvailable
      selectedOptions {
        name
        value
      }
      image {
        ...imageInformation
      }
      price {
        amount
        currencyCode
      }
      compareAtPrice {
        amount
        currencyCode
      }
    }
    $fragmentImage
  ''';

  static const fragmentImage = '''
    fragment imageInformation on Image {
      url(transform: {maxWidth: $_imageWidth, maxHeight: $_imageHeight, scale: $_scale})
      width
      height
    }
  ''';

  static const fragmentOrder = '''
  fragment orderInformation on Order {
    id
    financialStatus
    processedAt
    orderNumber
    currencyCode
    totalPrice {
      amount
    }
    statusUrl
    totalTax {
      amount
    }
    subtotalPrice {
      amount
    }
    totalShippingPrice {
      amount
    }
    shippingAddress {
      address1
      address2
      city
      company
      country
      firstName
      id
      lastName
      zip
      provinceCode
      phone
      province
      name
      longitude
      latitude
      lastName
    }
    lineItems(first: 100) {
      pageInfo {
        hasNextPage
        hasPreviousPage
      }
      edges {
        node {
          quantity
          title
          originalTotalPrice{
            amount
          }
          variant {
            id
            title
            image {
              ...imageInformation
            }
            price {
              amount
            }
            selectedOptions {
              name
              value
            }
            product {
              id
            }
          }
        }
      }
    }
  }
  $fragmentImage
  ''';

  static const fragmentCollection = '''
  fragment collectionInformation on Collection {
    id
    title
    description
    handle
    onlineStoreUrl
    image {
      ...imageInformation
    }
  }
  $fragmentImage
  ''';

  static const fragmentCartDiscountAllocation = '''
    fragment cartDiscountAllocationInformation on CartDiscountAllocation {
        targetType
        discountedAmount {
          amount
          currencyCode
        }
        discountApplication {
          targetSelection
          targetType
          allocationMethod
          value {
            __typename
            ... on PricingPercentageValue {
              percentage
            }
            ... on MoneyV2 {  
              amount
              currencyCode
            }
          }
        }
        ... on CartAutomaticDiscountAllocation {
          targetType
          title
          discountedAmount {
            amount
            currencyCode
          }
          discountApplication {
            allocationMethod
            targetSelection
            targetType
            value {
              ... on MoneyV2 {
                amount
                currencyCode
              }
              ... on PricingPercentageValue {
                percentage
              }
            }
          }
        }
        ... on CartCodeDiscountAllocation {
          code
          targetType
          discountedAmount {
            amount
            currencyCode
          }
          discountApplication {
            allocationMethod
            targetSelection
            targetType
            value {
              ... on MoneyV2 {
                amount
                currencyCode
              }
              ... on PricingPercentageValue {
                percentage
              }
            }
          }
        }
        ... on CartCustomDiscountAllocation {
          targetType
          title
          discountedAmount {
            amount
            currencyCode
          }
          discountApplication {
            allocationMethod
            targetSelection
            targetType
            value {
              ... on MoneyV2 {
                __typename
                amount
                currencyCode
              }
              ... on PricingPercentageValue {
                __typename
                percentage
              }
            }
          }
        }
      }
  ''';
}
