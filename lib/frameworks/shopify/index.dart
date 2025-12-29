import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:inspireui/widgets/coupon_card.dart';
import 'package:provider/provider.dart';

// import 'package:shopify_checkout_sheet_kit/shopify_checkout_sheet_kit.dart';

import '../../common/config.dart';
import '../../common/config/models/cart_config.dart';
import '../../common/constants.dart'
    show kBlogLayout, kIsWeb, printError, printLog;
import '../../common/error_codes/error_codes.dart';
import '../../common/tools.dart';
import '../../models/cart/cart_item_meta_data.dart';
import '../../models/cart/cart_model_shopify.dart';
import '../../models/entities/filter_sorty_by.dart';
import '../../models/entities/index.dart';
import '../../models/index.dart'
    show
        Address,
        AppModel,
        CartModel,
        Country,
        CountryState,
        Coupons,
        Discount,
        Order,
        PaymentMethod,
        Product,
        ShippingMethodModel,
        User,
        UserModel;
import '../../modules/analytics/analytics.dart';
import '../../modules/product_reviews/product_reviews_index.dart';
import '../../modules/re_order/re_order_index.dart';
import '../../routes/flux_navigate.dart';
import '../../screens/checkout/payment_webview_screen.dart';
import '../../screens/checkout/webview_checkout_success_screen.dart';
import '../../services/index.dart';
import '../frameworks.dart';
import '../product_variant_mixin.dart';
import 'screens/account/shopify_account_screen.dart';
import 'screens/account/shopify_change_password_screen.dart';
import 'screens/account/shopify_personal_info_screen.dart';
import 'services/shopify_service.dart';
import 'shopify_variant_mixin.dart';

const _defaultTitle = 'Title';
const _defaultOptionTitle = 'Default Title';

class ShopifyWidget extends BaseFrameworks
    with ProductVariantMixin, ShopifyVariantMixin {
  final ShopifyService shopifyService;

  // ShopifyCustomerAccountService? customerAccountService;

  ShopifyWidget(this.shopifyService);

  @override
  bool get enableProductReview => false; // currently did not support review

  @override
  void updateUserInfo({
    User? loggedInUser,
    context,
    required onError,
    onSuccess,
    required String currentPassword,
    required userDisplayName,
    userEmail,
    username,
    userNiceName,
    userUrl,
    userPassword,
    userFirstname,
    userLastname,
    userPhone,
  }) {
    final params = {
      // 'email': userEmail,
      'firstName': userFirstname,
      'lastName': userLastname,
      if (currentPassword.isNotEmpty) 'password': userPassword,
      'phone': userPhone,
    };

    Services().api.updateUserInfo(params, loggedInUser!.cookie)!.then((value) {
      params['cookie'] = loggedInUser.cookie;
      // ignore: unnecessary_null_comparison
      onSuccess!(value != null
          ? User.fromShopifyJson(value, loggedInUser.cookie,
              tokenExpiresAt: loggedInUser.expiresAt)
          : loggedInUser);
    }).catchError((e) {
      onError(e.toString());
    });
  }

  @override
  Widget renderVariantCartItem(
    BuildContext context,
    Product product,
    variation,
    Map? options, {
    AttributeProductCartStyle style = AttributeProductCartStyle.normal,
  }) {
    var list = <Widget>[];
    for (var att in variation.attributes) {
      final name = att.name;
      final option = att.option;
      if (name == _defaultTitle && option == _defaultOptionTitle) {
        continue;
      }

      list.add(Row(
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 50.0, maxWidth: 200),
            child: Text(
              '${name?[0].toUpperCase()}${name?.substring(1)} ',
            ),
          ),
          name == 'color'
              ? Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: HexColor(
                          context.getHexColor(option),
                        ),
                      ),
                    ),
                  ),
                )
              : Expanded(
                  child: Text(
                    option ?? '',
                    textAlign: TextAlign.end,
                  ),
                ),
        ],
      ));
      list.add(const SizedBox(
        height: 5.0,
      ));
    }

    return Column(children: list);
  }

  @override
  void loadShippingMethods(
    BuildContext context,
    CartModel cartModel,
    bool beforehand,
  ) {
//    if (!beforehand) return;
    if (context.mounted == false) return;

    final cartModel = Provider.of<CartModel>(context, listen: false);
    final token = context.read<UserModel>().user?.cookie;
    final langCode = context.read<AppModel>().langCode;
    context.read<ShippingMethodModel>().getShippingMethods(
          cartModel: cartModel,
          token: token,
          checkoutId: cartModel.getCartId(),
          langCode: langCode,
        );
  }

  @override
  String? getPriceItemInCart(
    Product product,
    CartItemMetaData? cartItemMetaData,
    currencyRate,
    String? currency, {
    int quantity = 1,
  }) {
    final variation = cartItemMetaData?.variation;
    return variation != null && variation.id != null
        ? PriceTools.getVariantPriceProductValue(
            variation,
            currencyRate,
            currency,
            quantity: quantity,
            onSale: true,
            selectedOptions: cartItemMetaData?.addonsOptions,
          )
        : PriceTools.getPriceProduct(product, currencyRate, currency,
            quantity: quantity, onSale: true);
  }

  @override
  Future<List<Country>> loadCountries() async {
    var countries = <Country>[];
    if (kDefaultCountry.isNotEmpty) {
      for (var item in kDefaultCountry) {
        countries.addData(item);
      }
    }
    return countries;
  }

  @override
  Future<List<CountryState>> loadStates(Country country) async {
    var states = <CountryState>[];

    // Check if the country is Egypt
    if (country.id == 'EG' || country.id == 'eg') {
      // Egyptian Governorates
      states = [
        CountryState(id: 'cairo', code: 'Cairo', name: 'Cairo'),
        CountryState(id: 'alexandria', code: 'Alexandria', name: 'Alexandria'),
        CountryState(id: 'giza', code: 'Giza', name: 'Giza'),
        CountryState(id: 'sharqia', code: 'Sharqia', name: 'Sharqia'),
        CountryState(id: 'dakahlia', code: 'Dakahlia', name: 'Dakahlia'),
        CountryState(id: 'beheira', code: 'Beheira', name: 'Beheira'),
        CountryState(id: 'minya', code: 'Minya', name: 'Minya'),
        CountryState(id: 'qalyubia', code: 'Qalyubia', name: 'Qalyubia'),
        CountryState(id: 'gharbia', code: 'Gharbia', name: 'Gharbia'),
        CountryState(id: 'aswan', code: 'Aswan', name: 'Aswan'),
        CountryState(id: 'asyut', code: 'Asyut', name: 'Asyut'),
        CountryState(id: 'beni suef', code: 'Beni Suef', name: 'Beni Suef'),
        CountryState(id: 'port said', code: 'Port Said', name: 'Port Said'),
        CountryState(id: 'damietta', code: 'Damietta', name: 'Damietta'),
        CountryState(id: 'faiyum', code: 'Faiyum', name: 'Faiyum'),
        CountryState(id: 'ismailia', code: 'Ismailia', name: 'Ismailia'),
        CountryState(
            id: 'kafr el sheikh',
            code: 'Kafr El Sheikh',
            name: 'Kafr El Sheikh'),
        CountryState(id: 'luxor', code: 'Luxor', name: 'Luxor'),
        CountryState(id: 'matrouh', code: 'Matrouh', name: 'Matrouh'),
        CountryState(id: 'monufia', code: 'Monufia', name: 'Monufia'),
        CountryState(id: 'red sea', code: 'Red Sea', name: 'Red Sea'),
        CountryState(
            id: 'north sinai', code: 'North Sinai', name: 'North Sinai'),
        CountryState(
            id: 'south sinai', code: 'South Sinai', name: 'South Sinai'),
        CountryState(id: 'suez', code: 'Suez', name: 'Suez'),
        CountryState(id: 'sohag', code: 'Sohag', name: 'Sohag'),
        CountryState(id: 'qena', code: 'Qena', name: 'Qena'),
        CountryState(id: 'new valley', code: 'New Valley', name: 'New Valley'),
      ];
    } else {
      // For other countries, try to load from configuration
      try {
        final items = await Tools.loadStatesByCountry(country.id!);
        if (items.isNotEmpty) {
          for (var item in items) {
            states.add(CountryState.fromConfig(item));
          }
        }
      } catch (e) {
        printLog('Error loading states: $e');
      }
    }

    return states;
  }

  @override
  Future<bool> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
    Function(String)? onError,
    Function(User?)? onSuccess,
  }) async {
    try {
      printLog('::::request changePassword for email: $email');

      // Step 1: Verify current password
      final isCurrentPasswordValid = await shopifyService.verifyPassword(
        email: email,
        password: currentPassword,
      );

      if (!isCurrentPasswordValid) {
        onError?.call('Current password is incorrect');
        return false;
      }

      // Step 2: Update password if current password is valid
      final updateParams = {
        'password': newPassword,
      };

      // Get current user's access token for the update
      final tokenResult = await shopifyService.createAccessToken(
        email: email,
        password: currentPassword,
      );

      if (tokenResult.token == null) {
        onError?.call('Failed to authenticate user');
        return false;
      }

      await shopifyService.updateUserInfo(
        updateParams,
        tokenResult.token,
      );

      // Step 3: Create new access token with new password to get updated user info
      final newTokenResult = await shopifyService.createAccessToken(
        email: email,
        password: newPassword,
      );

      if (newTokenResult.token == null) {
        onError?.call(
            'Password updated but failed to get new authentication token');
        return false;
      }

      // Get updated user info with new token
      final updatedUser = await shopifyService.getUserInfo(
        newTokenResult.token,
        tokenExpiresAt: newTokenResult.expiresAt,
      );

      onSuccess?.call(updatedUser);
      printLog('::::changePassword successful');
      return true;
    } catch (e) {
      printLog('::::changePassword error: ${e.toString()}');
      onError?.call('Failed to change password: ${e.toString()}');
      return false;
    }
  }

  @override
  Future<void> resetPassword(BuildContext context, String username) async {
    try {
      final val = await (Provider.of<UserModel>(context, listen: false)
          .submitForgotPassword(forgotPwLink: '', data: {'email': username}));
      if (val?.isEmpty ?? true) {
        Future.delayed(
            const Duration(seconds: 1), () => Navigator.of(context).pop());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.of(context).checkConfirmLink),
          duration: const Duration(seconds: 5),
        ));
      } else {
        Tools.showSnackBar(ScaffoldMessenger.of(context), val);
      }
      return;
    } catch (e) {
      printLog(e);
      if (e.toString().contains('UNIDENTIFIED_CUSTOMER')) {
        throw Exception(S.of(context).emailDoesNotExist);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  @override
  Widget renderRelatedBlog({
    categoryId,
    required kBlogLayout type,
    EdgeInsetsGeometry? padding,
  }) {
    return const SizedBox();
  }

  @override
  Widget renderCommentField(dynamic postId) {
    return const SizedBox();
  }

  @override
  Widget renderCommentLayout(dynamic postId, kBlogLayout type) {
    return const SizedBox();
  }

  @override
  Widget productReviewWidget(
    Product product, {
    bool isStyleExpansion = true,
    bool isShowEmpty = false,
    Widget Function(int)? builderTitle,
  }) {
    return ProductReviewsIndex(
      product: product,
      isStyleExpansion: isStyleExpansion,
      isShowEmpty: isShowEmpty,
      builderTitle: builderTitle,
    );
  }

  @override
  List<OrderByType> get supportedSortByOptions =>
      [OrderByType.date, OrderByType.price, OrderByType.title];

  @override
  Future<void> applyCoupon(
    context, {
    Coupons? coupons,
    String? code,
    Function? success,
    Function? error,
    bool cartChanged = false,
  }) async {
    final cartModel =
        Provider.of<CartModel>(context, listen: false) as CartModelShopify;
    try {
      var cartDataShopify = cartModel.cartDataShopify;

      if (cartChanged || cartDataShopify == null) {
        cartDataShopify = await shopifyService.createCart(cartModel: cartModel);
      }

      if (cartDataShopify == null) {
        error!('Cannot apply coupon for now. Please try again later.');
        return;
      }
      cartModel.setCartDataShopify(cartDataShopify);

      final cartAppliedCoupon = await shopifyService.applyCouponWithCartId(
        cartId: cartDataShopify.id,
        discountCode: code!,
      );

      cartModel.setCartDataShopify(cartAppliedCoupon);
      final coupon = cartAppliedCoupon?.discountCodeApplied;
      if (cartAppliedCoupon != null && coupon != null) {
        printLog(
            '::::::::::::::::::: applyCoupon success ::::::::::::::::::::::');
        printLog('Cart ID: ${cartAppliedCoupon.id} applied coupon: [$coupon]');
        success!(Discount(
            discountValue: cartAppliedCoupon.totalDiscount,
            coupon: Coupon(
              code: coupon,
              amount: cartAppliedCoupon.totalDiscount,
            )));
        return;
      }

      error!(S.of(context).couponInvalid);
    } on Exception catch (e, trace) {
      printLog('::::::::::::::::::: applyCoupon error ::::::::::::::::::::::');
      printError(e, trace);
      error!(e.toString());
    }
  }

  @override
  Future<void> removeCoupon(context) async {
    final cartModel = Provider.of<CartModel>(context, listen: false);
    final cartDataShopify = cartModel.cartDataShopify;
    if (cartDataShopify == null) return;
    try {
      final cartRemovedCoupon =
          await shopifyService.removeCouponWithCartId(cartDataShopify.id);

      printLog(
          '::::::::::::::::::: removeCoupon success ::::::::::::::::::::::');
      printLog('Cart ID: ${cartRemovedCoupon?.id} removed coupon');
      cartModel.setCartDataShopify(cartRemovedCoupon);
    } catch (e, trace) {
      printLog('::::::::::::::::::: removeCoupon error ::::::::::::::::::::::');
      printError(e, trace);
    }
  }

  @override
  Map<dynamic, dynamic> getPaymentUrl(context) {
    return {
      'headers': {},
      'url': Provider.of<CartModel>(context, listen: false)
          .cartDataShopify
          ?.checkoutUrl
    };
  }

  @override
  Future<void> doCheckout(
    context, {
    Function? success,
    Function? loading,
    Function? error,
  }) async {
    final cartModel =
        Provider.of<CartModel>(context, listen: false) as CartModelShopify;

    final currentCart = cartModel.cartDataShopify;
    final discountCodeApplied = currentCart?.discountCodeApplied;

    try {
      final cartDataShopify =
          await shopifyService.createCart(cartModel: cartModel);
      if (cartDataShopify == null) {
        error!('Cannot create cart right now. Please try again later.');
        return;
      }

      if (discountCodeApplied != null) {
        final cartAppliedCoupon = await shopifyService.applyCouponWithCartId(
          cartId: cartDataShopify.id,
          discountCode: discountCodeApplied,
        );
        cartModel.setCartDataShopify(cartAppliedCoupon);
      } else {
        // Use new cart
        cartModel.setCartDataShopify(cartDataShopify);
      }

      if (kPaymentConfig.enableWebviewCheckout) {
        /// Navigate to Webview payment

        String? orderNum;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebview(
              url: cartDataShopify.checkoutUrl,
              token: cartModel.user?.cookie,
              onFinish: (number) async {
                orderNum = number;
              },
            ),
          ),
        );
        if (orderNum != null && !kIsWeb) {
          loading!(true);
          unawaited(cartModel.clearCart());
          Analytics.triggerPurchased(
              Order(
                number: orderNum,
                total: cartDataShopify.cost.totalAmount(),
                id: '',
              ),
              context);
          final user = cartModel.user;
          if (user != null && (user.cookie?.isNotEmpty ?? false)) {
            final order =
                await shopifyService.getLatestOrder(cookie: user.cookie ?? '');
            if (order != null) {
              orderNum = order.number;
            }
          }
          if (kPaymentConfig.showNativeCheckoutSuccessScreenForWebview) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WebviewCheckoutSuccessScreen(
                  order: Order(number: orderNum),
                ),
              ),
            );
          }
        }
        loading!(false);
        return;
      }
      success!();
    } catch (e, trace) {
      printError(e, trace);
      final errorMessage =
          e is ErrorType ? e.getMessage(context) : e.toString();
      error!(errorMessage);
    }
  }

  @override
  void placeOrder(
    context, {
    required CartModel cartModel,
    PaymentMethod? paymentMethod,
    Function? onLoading,
    Function? success,
    Function? error,
  }) async {
    {
      final cartDataShopify = cartModel.cartDataShopify;
      final cartId = cartDataShopify?.id;
      if (cartId == null) {
        error!('Cart is empty');
        return;
      }
      final deliveryDate = cartModel.selectedDate?.dateTime;
      if (deliveryDate != null) {
        await shopifyService.updateCartAttributes(
          cartId: cartModel.cartDataShopify!.id,
          deliveryDate: deliveryDate,
        );
      }

      final note = cartModel.notes;
      if (note != null) {
        await shopifyService.updateCartNote(
          cartId: cartId,
          note: note,
        );
      }

      // final shopifyCheckout = ShopifyCheckoutSheetKit();
      // shopifyCheckout.setCheckoutCallback(
      //   onCancel: () {
      //     error!('Payment cancelled');
      //     return;
      //   },
      //   onFail: (err) {
      //     error!(err.message);
      //   },
      //   onComplete: (orderCompletedEvent) async {
      //     if (!cartModel.user!.isGuest) {
      //       final order = await shopifyService.getLatestOrder(
      //           cookie: cartModel.user?.cookie ?? '');
      //       if (order == null) return error!('Checkout failed');
      //       success!(order);
      //       return;
      //     }
      //     success!(Order());
      //     return;
      //   },
      // );
      // shopifyCheckout.showCheckoutSheet(
      //     checkoutUrl: cartModel.cartDataShopify!.checkoutUrl);
      // onLoading!(false);
      // return;

      String? orderNum;
      final user = cartModel.user;
      await FluxNavigate.push(
        MaterialPageRoute(
          builder: (context) => PaymentWebview(
            token: user?.cookie,
            url: cartModel.cartDataShopify!.checkoutUrl,
            onFinish: (number) async {
              // Success
              orderNum = number;
              if (number == '0') {
                if (user != null && (user.cookie?.isNotEmpty ?? false)) {
                  /// Delay to await actually order create
                  await Future.delayed(const Duration(seconds: 1));
                  final order = await shopifyService.getLatestOrder(
                      cookie: user.cookie ?? '');
                  if (order == null) return error!('Checkout failed');
                  Analytics.triggerPurchased(
                      Order(
                        number: orderNum,
                        total: cartModel
                                .cartDataShopify?.cost.totalAmount.amount ??
                            0,
                        id: '',
                      ),
                      context);
                  success!(order);
                  return;
                }
                success!(Order());
                return;
              }
            },
            onClose: () {
              // Check in case the payment is successful but the webview is still displayed, need to press the close button
              if (orderNum != '0') {
                error!('Payment cancelled');
                return;
              }
            },
          ),
        ),
        forceRootNavigator: true,
        context: context,
      );
      onLoading!(false);
    }
  }

  @override
  Future<bool> updateCartBuyerIdentity({
    required CartModel cartModel,
    required Address? address,
  }) async {
    final cartData = cartModel.cartDataShopify;
    if (cartData == null) return false;

    // Make sure we have a customer identity first
    if (cartData.buyerIdentity.customer == null) {
      final result = await shopifyService
          .updateCartBuyerIdentity(cartId: cartData.id, buyerIdentity: {});
      if (result == null) {
        return false;
      }
      cartModel.setCartDataShopify(result);
    }
    // Update delivery address from customer address or create a new one
    return cartDeliveryAddressUpdate(cartModel: cartModel, address: address);
  }

  Future<bool> cartDeliveryAddressUpdate({
    required CartModel cartModel,
    required Address? address,
  }) async {
    if (address == null) return false;

    if (address.id != null && address.id!.contains('MailingAddress')) {
      final cartDataShopify =
          await shopifyService.updateCartDeliveryAddressesWithId(
        cartId: cartModel.getCartId(),
        customerAddressId: address.id!,
      );
      if (cartDataShopify == null) {
        return false;
      }
      cartModel.setCartDataShopify(cartDataShopify);
      return true;
    }

    final cartDataShopify = await shopifyService.updateCartDeliveryAddresses(
      cartId: cartModel.getCartId(),
      address: address,
    );
    if (cartDataShopify == null) {
      return false;
    }
    cartModel.setCartDataShopify(cartDataShopify);
    return true;
  }

  @override
  String calculateOrderSubtotal({
    required Order order,
    Map<String, dynamic>? currencyRate,
    String? currencyCode,
  }) {
    return PriceTools.getCurrencyFormatted(order.subtotal, currencyRate,
        currency: currencyCode)!;
  }

  @override
  Widget reOrderButton(Order order) {
    return ReOrderIndex(
      order: order,
    );
  }

  @override
  Future<bool>? syncCartFromWebsite(
      String? token, CartModel cartModel, BuildContext context) async {
    // Avoid to clear cartDataShopify when user login at the step select address
    return true;
  }

  @override
  Widget renderAccountScreen() => const ShopifyAccountScreen();

  @override
  Widget renderChangePasswordScreen() => const ShopifyChangePasswordScreen();

  @override
  Widget renderPersonalInfoScreen() => const ShopifyPersonalInfoScreen();
}
