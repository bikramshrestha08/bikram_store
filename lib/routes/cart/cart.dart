import 'package:linkeat/utils/store.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linkeat/l10n/localizations.dart';
import 'package:linkeat/states/cart.dart';
import 'package:linkeat/models/order.dart';
import 'package:linkeat/utils/sputil.dart';
import 'package:linkeat/config.dart';

import '../../models/routeArguments.dart';

// Show dialog to enter notes
Future<void> _showNotesDialog(BuildContext context, CartItem cartItem) async {
  final TextEditingController notesController = TextEditingController();

  // Create a dialog to enter notes
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Add Notes for ${cartItem.product!.name!}'),
        content: TextField(
          controller: notesController,
          decoration: InputDecoration(hintText: 'Enter your notes here'),
          maxLines: 3, // Allow multiple lines
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () {
              // Save the notes to the cart item
              cartItem.notes =
                  notesController.text; // Assuming you have a notes property
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

// "Empty Cart" button component
class _EmptyCartButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var cart = Provider.of<CartModel>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          cart.emptyCart(); // Clears the entire cart
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cart has been emptied!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: Text('Empty Cart'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.red, // Button color
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          textStyle: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class Cart extends StatelessWidget {
  static const routeName = '/cart';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cart = Provider.of<CartModel>(context);
    String? storeId;
    if (cart.storeDetail != null && cart.storeDetail!.uuid != null) {
      storeId = cart.storeDetail!.uuid;
    }
    var availableOrder = true;
    String? notAvaliableOrderReason = '';
    if (cart.type == OrderType.TAKEAWAY) {
      var _pickupTimeOptions =
          getTakeAwayTimeOptions(cart.storeDetail!.businessHour!);
      if (_pickupTimeOptions == null ||
          !cart.storeDetail!.storeConfig!.acceptTakeaway!) {
        availableOrder = false;
        notAvaliableOrderReason =
            AppLocalizations.of(context)!.pickupNotAvailable;
      }
    }

    if (cart.type == OrderType.DELIVERY) {
      if (!cart.storeDetail!.storeConfig!.acceptDelivery!) {
        availableOrder = false;
        notAvaliableOrderReason =
            AppLocalizations.of(context)!.deliveryNotAvailable;
      } else {
        var validDeliveryRanges = cart.storeDetail!.deliveryCfg!.deliveryRanges!
            .where((deliveryRange) =>
                deliveryRange.postCodes!.contains(Constants.DELIVERY_POSTCODE))
            .toList();
        if (validDeliveryRanges.isEmpty) {
          FocusScope.of(context).requestFocus(new FocusNode());
          availableOrder = false;
          notAvaliableOrderReason =
              '${AppLocalizations.of(context)!.postCodeNotAvailable} (${Constants.DELIVERY_POSTCODE})';
        } else {
          var deliveryRange = validDeliveryRanges[0];
          if (cart.cartTotal < deliveryRange.minimalOrderPrice!) {
            FocusScope.of(context).requestFocus(new FocusNode());
            availableOrder = false;
            notAvaliableOrderReason =
                '${AppLocalizations.of(context)!.deliveryMinOrderError} (\$${(deliveryRange.minimalOrderPrice! / 100).toString()})';
          } else {
            var _deliveryTimeOptions = getDeliveryTimeOptions(
                Constants.DELIVERY_POSTCODE, deliveryRange);
            if (_deliveryTimeOptions == null) {
              availableOrder = false;
              notAvaliableOrderReason =
                  AppLocalizations.of(context)!.deliveryNotAvailable;
            }
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(
          color: Colors.black87,
        ),
        title: Text(
          AppLocalizations.of(context)!.cart!,
          style: textTheme.headline5,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Column(
          children: [
            Expanded(child: _CartList()),
            _EmptyCartButton(),
          ],
        ),
      ),
      bottomNavigationBar: _CheckoutBar(
        availableOrder: availableOrder,
        notAvaliableOrderReason: notAvaliableOrderReason,
        storeId: storeId,
      ),
    );
  }
}

class _CartList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var cart = Provider.of<CartModel>(context);
    return ListView.builder(
      itemCount: cart.cartItems.length,
      itemBuilder: (context, index) =>
          _CartItem(cartItem: cart.cartItems[index], index: index),
    );
  }
}

class _CartItem extends StatelessWidget {
  final CartItem cartItem;
  final int index;
  final String? notes;

  _CartItem({
    Key? key,
    required this.cartItem,
    required this.index,
    this.notes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    var cart = Provider.of<CartModel>(context, listen: false);
    return GestureDetector(
      // Change to GestureDetector to handle taps
      onTap: () {
        _showNotesDialog(context, cartItem); // Show the notes dialog
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: LimitedBox(
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  SizedBox(
                    width: 30.0,
                    child: Text(cartItem.quantity.toString() + ' X'),
                  ),
                  Expanded(
                    child: Text(
                      cartItem.product!.name!,
                      style: textTheme.subtitle2,
                    ),
                  ),
                  Text('\$' + (cartItem.product!.price! / 100).toString()),
                  SizedBox(width: 10.0),
                  IconButton(
                    iconSize: 20.0,
                    icon: Icon(
                      EvaIcons.closeCircleOutline,
                      color: Colors.grey,
                    ),
                    tooltip: 'Remove',
                    onPressed: () {
                      cart.removeFromCart(index);
                    },
                  ),
                ],
              ),
              // Display notes if available
              if (cartItem.notes != null && cartItem.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Notes: ${cartItem.notes}', // Show the notes
                    style: textTheme.caption,
                  ),
                ),
              Divider(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final bool availableOrder;
  final String? notAvaliableOrderReason;
  final String? storeId;

  const _CheckoutBar(
      {Key? key,
      required this.availableOrder,
      required this.notAvaliableOrderReason,
      required this.storeId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var cart = Provider.of<CartModel>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    var platform = Theme.of(context).platform;
    double paddingBottom = 0;
    if (platform == TargetPlatform.iOS &&
        MediaQuery.of(context).padding.bottom > 0) {
      paddingBottom = 20;
    }
    return Container(
        color: availableOrder ? colorScheme.primary : Colors.grey,
        child: availableOrder
            ? SafeArea(
                minimum: EdgeInsets.only(bottom: paddingBottom),
                bottom: false,
                child: Container(
                  color: colorScheme.primary,
                  child: TextButton(
                    onPressed: () {
                      String? token =
                          SpUtil.preferences.getString('accessToken');
                      if (token != null) {
                        Navigator.pushNamed(
                          context,
                          cart.type == OrderType.DELIVERY
                              ? '/checkoutDelivery'
                              : '/checkoutTakeaway',
                        );
                      } else {
                        Navigator.pushNamed(
                          context,
                          '/login',
                          arguments: (storeId: storeId),
                        );
                      }
                    },
                    child: Text(
                      AppLocalizations.of(context)!.checkout!,
                      style: textTheme.headline6!.copyWith(color: Colors.white),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.all(16.0),
                    ),
                  ),
                ),
              )
            : SafeArea(
                minimum: EdgeInsets.only(bottom: paddingBottom),
                bottom: false,
                child: Container(
                  color: Colors.grey,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      notAvaliableOrderReason ?? '',
                      style: textTheme.subtitle1!.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ));
  }
}
