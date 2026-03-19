/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import '../auth/email_idp_endpoint.dart' as _i2;
import '../auth/jwt_refresh_endpoint.dart' as _i3;
import '../endpoints/attachment_endpoint.dart' as _i4;
import '../endpoints/auth_endpoint.dart' as _i5;
import '../endpoints/comment_endpoint.dart' as _i6;
import '../endpoints/reference_endpoint.dart' as _i7;
import '../endpoints/ticket_endpoint.dart' as _i8;
import '../greetings/greeting_endpoint.dart' as _i9;
import 'package:ticketmanagement_server_server/src/generated/category.dart'
    as _i10;
import 'package:ticketmanagement_server_server/src/generated/asset.dart'
    as _i11;
import 'package:ticketmanagement_server_server/src/generated/department.dart'
    as _i12;
import 'package:ticketmanagement_server_server/src/generated/emergency_contact.dart'
    as _i13;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i14;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i15;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'emailIdp': _i2.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'jwtRefresh': _i3.JwtRefreshEndpoint()
        ..initialize(
          server,
          'jwtRefresh',
          null,
        ),
      'attachment': _i4.AttachmentEndpoint()
        ..initialize(
          server,
          'attachment',
          null,
        ),
      'auth': _i5.AuthEndpoint()
        ..initialize(
          server,
          'auth',
          null,
        ),
      'comment': _i6.CommentEndpoint()
        ..initialize(
          server,
          'comment',
          null,
        ),
      'reference': _i7.ReferenceEndpoint()
        ..initialize(
          server,
          'reference',
          null,
        ),
      'ticket': _i8.TicketEndpoint()
        ..initialize(
          server,
          'ticket',
          null,
        ),
      'greeting': _i9.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
    };
    connectors['emailIdp'] = _i1.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint).login(
                session,
                email: params['email'],
                password: params['password'],
              ),
        ),
        'startRegistration': _i1.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .startRegistration(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyRegistrationCode': _i1.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _i1.ParameterDescription(
              name: 'accountRequestId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _i1.ParameterDescription(
              name: 'verificationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _i1.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _i1.ParameterDescription(
              name: 'registrationToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'startPasswordReset': _i1.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .startPasswordReset(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyPasswordResetCode': _i1.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _i1.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _i1.ParameterDescription(
              name: 'verificationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishPasswordReset': _i1.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _i1.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
        'hasAccount': _i1.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['jwtRefresh'] = _i1.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _i1.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _i1.ParameterDescription(
              name: 'refreshToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['jwtRefresh'] as _i3.JwtRefreshEndpoint)
                  .refreshAccessToken(
                    session,
                    refreshToken: params['refreshToken'],
                  ),
        ),
      },
    );
    connectors['attachment'] = _i1.EndpointConnector(
      name: 'attachment',
      endpoint: endpoints['attachment']!,
      methodConnectors: {
        'uploadAttachment': _i1.MethodConnector(
          name: 'uploadAttachment',
          params: {
            'ticketId': _i1.ParameterDescription(
              name: 'ticketId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'uploaderId': _i1.ParameterDescription(
              name: 'uploaderId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'fileName': _i1.ParameterDescription(
              name: 'fileName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'mimeType': _i1.ParameterDescription(
              name: 'mimeType',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'fileData': _i1.ParameterDescription(
              name: 'fileData',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'fileSize': _i1.ParameterDescription(
              name: 'fileSize',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['attachment'] as _i4.AttachmentEndpoint)
                  .uploadAttachment(
                    session,
                    params['ticketId'],
                    params['uploaderId'],
                    params['fileName'],
                    params['mimeType'],
                    params['fileData'],
                    params['fileSize'],
                  ),
        ),
        'getAttachments': _i1.MethodConnector(
          name: 'getAttachments',
          params: {
            'ticketId': _i1.ParameterDescription(
              name: 'ticketId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['attachment'] as _i4.AttachmentEndpoint)
                  .getAttachments(
                    session,
                    params['ticketId'],
                  ),
        ),
        'deleteAttachment': _i1.MethodConnector(
          name: 'deleteAttachment',
          params: {
            'attachmentId': _i1.ParameterDescription(
              name: 'attachmentId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['attachment'] as _i4.AttachmentEndpoint)
                  .deleteAttachment(
                    session,
                    params['attachmentId'],
                  ),
        ),
      },
    );
    connectors['auth'] = _i1.EndpointConnector(
      name: 'auth',
      endpoint: endpoints['auth']!,
      methodConnectors: {
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'username': _i1.ParameterDescription(
              name: 'username',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i5.AuthEndpoint).login(
                session,
                params['username'],
                params['password'],
              ),
        ),
        'getUsers': _i1.MethodConnector(
          name: 'getUsers',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['auth'] as _i5.AuthEndpoint).getUsers(session),
        ),
        'getITStaff': _i1.MethodConnector(
          name: 'getITStaff',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['auth'] as _i5.AuthEndpoint).getITStaff(session),
        ),
        'register': _i1.MethodConnector(
          name: 'register',
          params: {
            'username': _i1.ParameterDescription(
              name: 'username',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'fullName': _i1.ParameterDescription(
              name: 'fullName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'roleId': _i1.ParameterDescription(
              name: 'roleId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'deptId': _i1.ParameterDescription(
              name: 'deptId',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i5.AuthEndpoint).register(
                session,
                params['username'],
                params['password'],
                params['fullName'],
                params['phone'],
                params['roleId'],
                params['deptId'],
              ),
        ),
        'updateUser': _i1.MethodConnector(
          name: 'updateUser',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'fullName': _i1.ParameterDescription(
              name: 'fullName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'roleId': _i1.ParameterDescription(
              name: 'roleId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'deptId': _i1.ParameterDescription(
              name: 'deptId',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i5.AuthEndpoint).updateUser(
                session,
                params['userId'],
                params['fullName'],
                params['phone'],
                params['roleId'],
                params['deptId'],
              ),
        ),
        'resetPassword': _i1.MethodConnector(
          name: 'resetPassword',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i5.AuthEndpoint).resetPassword(
                session,
                params['userId'],
                params['newPassword'],
              ),
        ),
        'deleteUser': _i1.MethodConnector(
          name: 'deleteUser',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i5.AuthEndpoint).deleteUser(
                session,
                params['userId'],
              ),
        ),
        'updateFcmToken': _i1.MethodConnector(
          name: 'updateFcmToken',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'token': _i1.ParameterDescription(
              name: 'token',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i5.AuthEndpoint).updateFcmToken(
                session,
                params['userId'],
                params['token'],
              ),
        ),
      },
    );
    connectors['comment'] = _i1.EndpointConnector(
      name: 'comment',
      endpoint: endpoints['comment']!,
      methodConnectors: {
        'getComments': _i1.MethodConnector(
          name: 'getComments',
          params: {
            'ticketId': _i1.ParameterDescription(
              name: 'ticketId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['comment'] as _i6.CommentEndpoint).getComments(
                    session,
                    params['ticketId'],
                  ),
        ),
        'addComment': _i1.MethodConnector(
          name: 'addComment',
          params: {
            'ticketId': _i1.ParameterDescription(
              name: 'ticketId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'commentText': _i1.ParameterDescription(
              name: 'commentText',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['comment'] as _i6.CommentEndpoint).addComment(
                    session,
                    params['ticketId'],
                    params['userId'],
                    params['commentText'],
                  ),
        ),
      },
    );
    connectors['reference'] = _i1.EndpointConnector(
      name: 'reference',
      endpoint: endpoints['reference']!,
      methodConnectors: {
        'getCategories': _i1.MethodConnector(
          name: 'getCategories',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['reference'] as _i7.ReferenceEndpoint)
                  .getCategories(session),
        ),
        'upsertCategory': _i1.MethodConnector(
          name: 'upsertCategory',
          params: {
            'cat': _i1.ParameterDescription(
              name: 'cat',
              type: _i1.getType<_i10.Category>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['reference'] as _i7.ReferenceEndpoint)
                  .upsertCategory(
                    session,
                    params['cat'],
                  ),
        ),
        'deleteCategory': _i1.MethodConnector(
          name: 'deleteCategory',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['reference'] as _i7.ReferenceEndpoint)
                  .deleteCategory(
                    session,
                    params['id'],
                  ),
        ),
        'getAssets': _i1.MethodConnector(
          name: 'getAssets',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['reference'] as _i7.ReferenceEndpoint)
                  .getAssets(session),
        ),
        'upsertAsset': _i1.MethodConnector(
          name: 'upsertAsset',
          params: {
            'asset': _i1.ParameterDescription(
              name: 'asset',
              type: _i1.getType<_i11.Asset>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['reference'] as _i7.ReferenceEndpoint).upsertAsset(
                    session,
                    params['asset'],
                  ),
        ),
        'deleteAsset': _i1.MethodConnector(
          name: 'deleteAsset',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['reference'] as _i7.ReferenceEndpoint).deleteAsset(
                    session,
                    params['id'],
                  ),
        ),
        'getDepartments': _i1.MethodConnector(
          name: 'getDepartments',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['reference'] as _i7.ReferenceEndpoint)
                  .getDepartments(session),
        ),
        'upsertDepartment': _i1.MethodConnector(
          name: 'upsertDepartment',
          params: {
            'dept': _i1.ParameterDescription(
              name: 'dept',
              type: _i1.getType<_i12.Department>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['reference'] as _i7.ReferenceEndpoint)
                  .upsertDepartment(
                    session,
                    params['dept'],
                  ),
        ),
        'deleteDepartment': _i1.MethodConnector(
          name: 'deleteDepartment',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['reference'] as _i7.ReferenceEndpoint)
                  .deleteDepartment(
                    session,
                    params['id'],
                  ),
        ),
        'getEmergencyContacts': _i1.MethodConnector(
          name: 'getEmergencyContacts',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['reference'] as _i7.ReferenceEndpoint)
                  .getEmergencyContacts(session),
        ),
        'upsertEmergencyContact': _i1.MethodConnector(
          name: 'upsertEmergencyContact',
          params: {
            'contact': _i1.ParameterDescription(
              name: 'contact',
              type: _i1.getType<_i13.EmergencyContact>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['reference'] as _i7.ReferenceEndpoint)
                  .upsertEmergencyContact(
                    session,
                    params['contact'],
                  ),
        ),
        'deleteEmergencyContact': _i1.MethodConnector(
          name: 'deleteEmergencyContact',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['reference'] as _i7.ReferenceEndpoint)
                  .deleteEmergencyContact(
                    session,
                    params['id'],
                  ),
        ),
      },
    );
    connectors['ticket'] = _i1.EndpointConnector(
      name: 'ticket',
      endpoint: endpoints['ticket']!,
      methodConnectors: {
        'getTickets': _i1.MethodConnector(
          name: 'getTickets',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'roleId': _i1.ParameterDescription(
              name: 'roleId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ticket'] as _i8.TicketEndpoint).getTickets(
                session,
                params['userId'],
                params['roleId'],
              ),
        ),
        'getUnassignedTickets': _i1.MethodConnector(
          name: 'getUnassignedTickets',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ticket'] as _i8.TicketEndpoint)
                  .getUnassignedTickets(session),
        ),
        'getTicketById': _i1.MethodConnector(
          name: 'getTicketById',
          params: {
            'ticketId': _i1.ParameterDescription(
              name: 'ticketId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['ticket'] as _i8.TicketEndpoint).getTicketById(
                    session,
                    params['ticketId'],
                  ),
        ),
        'createTicket': _i1.MethodConnector(
          name: 'createTicket',
          params: {
            'requesterId': _i1.ParameterDescription(
              name: 'requesterId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'categoryId': _i1.ParameterDescription(
              name: 'categoryId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'subject': _i1.ParameterDescription(
              name: 'subject',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'priority': _i1.ParameterDescription(
              name: 'priority',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'assetId': _i1.ParameterDescription(
              name: 'assetId',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['ticket'] as _i8.TicketEndpoint).createTicket(
                    session,
                    params['requesterId'],
                    params['categoryId'],
                    params['subject'],
                    params['description'],
                    params['priority'],
                    params['assetId'],
                  ),
        ),
        'assignTicket': _i1.MethodConnector(
          name: 'assignTicket',
          params: {
            'ticketId': _i1.ParameterDescription(
              name: 'ticketId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'assigneeId': _i1.ParameterDescription(
              name: 'assigneeId',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['ticket'] as _i8.TicketEndpoint).assignTicket(
                    session,
                    params['ticketId'],
                    params['assigneeId'],
                  ),
        ),
        'updateStatus': _i1.MethodConnector(
          name: 'updateStatus',
          params: {
            'ticketId': _i1.ParameterDescription(
              name: 'ticketId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'status': _i1.ParameterDescription(
              name: 'status',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['ticket'] as _i8.TicketEndpoint).updateStatus(
                    session,
                    params['ticketId'],
                    params['status'],
                  ),
        ),
        'proposeDeadline': _i1.MethodConnector(
          name: 'proposeDeadline',
          params: {
            'ticketId': _i1.ParameterDescription(
              name: 'ticketId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'proposedByUserId': _i1.ParameterDescription(
              name: 'proposedByUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'proposedDeadline': _i1.ParameterDescription(
              name: 'proposedDeadline',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['ticket'] as _i8.TicketEndpoint).proposeDeadline(
                    session,
                    params['ticketId'],
                    params['proposedByUserId'],
                    params['proposedDeadline'],
                  ),
        ),
        'approveDeadline': _i1.MethodConnector(
          name: 'approveDeadline',
          params: {
            'ticketId': _i1.ParameterDescription(
              name: 'ticketId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'action': _i1.ParameterDescription(
              name: 'action',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'adjustedDeadline': _i1.ParameterDescription(
              name: 'adjustedDeadline',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
            'adminNote': _i1.ParameterDescription(
              name: 'adminNote',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['ticket'] as _i8.TicketEndpoint).approveDeadline(
                    session,
                    params['ticketId'],
                    params['action'],
                    params['adjustedDeadline'],
                    params['adminNote'],
                  ),
        ),
        'confirmDeadline': _i1.MethodConnector(
          name: 'confirmDeadline',
          params: {
            'ticketId': _i1.ParameterDescription(
              name: 'ticketId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'confirmed': _i1.ParameterDescription(
              name: 'confirmed',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['ticket'] as _i8.TicketEndpoint).confirmDeadline(
                    session,
                    params['ticketId'],
                    params['confirmed'],
                  ),
        ),
      },
    );
    connectors['greeting'] = _i1.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _i1.MethodConnector(
          name: 'hello',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['greeting'] as _i9.GreetingEndpoint).hello(
                session,
                params['name'],
              ),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _i14.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _i15.Endpoints()
      ..initializeEndpoints(server);
  }
}
