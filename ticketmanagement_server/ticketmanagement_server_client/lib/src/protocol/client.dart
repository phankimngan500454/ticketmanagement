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
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i1;
import 'package:serverpod_client/serverpod_client.dart' as _i2;
import 'dart:async' as _i3;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i4;
import 'package:ticketmanagement_server_client/src/protocol/ticket_attachment.dart'
    as _i5;
import 'package:ticketmanagement_server_client/src/protocol/app_user.dart'
    as _i6;
import 'package:ticketmanagement_server_client/src/protocol/ticket_comment.dart'
    as _i7;
import 'package:ticketmanagement_server_client/src/protocol/category.dart'
    as _i8;
import 'package:ticketmanagement_server_client/src/protocol/asset.dart' as _i9;
import 'package:ticketmanagement_server_client/src/protocol/department.dart'
    as _i10;
import 'package:ticketmanagement_server_client/src/protocol/emergency_contact.dart'
    as _i11;
import 'package:ticketmanagement_server_client/src/protocol/ticket.dart'
    as _i12;
import 'package:ticketmanagement_server_client/src/protocol/greetings/greeting.dart'
    as _i13;
import 'protocol.dart' as _i14;

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _i1.EndpointEmailIdpBase {
  EndpointEmailIdp(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i3.Future<_i4.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _i3.Future<_i2.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _i3.Future<String> verifyRegistrationCode({
    required _i2.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _i3.Future<_i4.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _i3.Future<_i2.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _i3.Future<String> verifyPasswordResetCode({
    required _i2.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i3.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  @override
  _i3.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _i4.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _i3.Future<_i4.AuthSuccess> refreshAccessToken({
    required String refreshToken,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'jwtRefresh',
    'refreshAccessToken',
    {'refreshToken': refreshToken},
    authenticated: false,
  );
}

/// Handles file attachment CRUD for tickets.
/// Files stored as base64 strings in DB.
/// {@category Endpoint}
class EndpointAttachment extends _i2.EndpointRef {
  EndpointAttachment(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'attachment';

  /// Upload a file attachment for a ticket.
  _i3.Future<_i5.TicketAttachment> uploadAttachment(
    int ticketId,
    int uploaderId,
    String fileName,
    String mimeType,
    String fileData,
    int fileSize,
  ) => caller.callServerEndpoint<_i5.TicketAttachment>(
    'attachment',
    'uploadAttachment',
    {
      'ticketId': ticketId,
      'uploaderId': uploaderId,
      'fileName': fileName,
      'mimeType': mimeType,
      'fileData': fileData,
      'fileSize': fileSize,
    },
  );

  /// Get all attachments for a ticket.
  _i3.Future<List<_i5.TicketAttachment>> getAttachments(int ticketId) =>
      caller.callServerEndpoint<List<_i5.TicketAttachment>>(
        'attachment',
        'getAttachments',
        {'ticketId': ticketId},
      );

  /// Delete an attachment by ID.
  _i3.Future<void> deleteAttachment(int attachmentId) =>
      caller.callServerEndpoint<void>(
        'attachment',
        'deleteAttachment',
        {'attachmentId': attachmentId},
      );
}

/// Handles authentication: login, register, and user queries.
/// Access via `client.auth` on the Flutter client.
/// {@category Endpoint}
class EndpointAuth extends _i2.EndpointRef {
  EndpointAuth(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'auth';

  /// Login with username + password. Returns AppUser on success.
  _i3.Future<_i6.AppUser?> login(
    String username,
    String password,
  ) => caller.callServerEndpoint<_i6.AppUser?>(
    'auth',
    'login',
    {
      'username': username,
      'password': password,
    },
  );

  /// Get all users.
  _i3.Future<List<_i6.AppUser>> getUsers() =>
      caller.callServerEndpoint<List<_i6.AppUser>>(
        'auth',
        'getUsers',
        {},
      );

  /// Get IT staff (roleId == 2).
  _i3.Future<List<_i6.AppUser>> getITStaff() =>
      caller.callServerEndpoint<List<_i6.AppUser>>(
        'auth',
        'getITStaff',
        {},
      );

  /// Register a new user.
  _i3.Future<_i6.AppUser?> register(
    String username,
    String password,
    String fullName,
    String? phone,
    int roleId,
    int? deptId,
  ) => caller.callServerEndpoint<_i6.AppUser?>(
    'auth',
    'register',
    {
      'username': username,
      'password': password,
      'fullName': fullName,
      'phone': phone,
      'roleId': roleId,
      'deptId': deptId,
    },
  );

  /// Admin: update user profile (fullName, phone, roleId, deptId).
  _i3.Future<_i6.AppUser?> updateUser(
    int userId,
    String fullName,
    String? phone,
    int roleId,
    int? deptId,
  ) => caller.callServerEndpoint<_i6.AppUser?>(
    'auth',
    'updateUser',
    {
      'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'roleId': roleId,
      'deptId': deptId,
    },
  );

  /// Admin: reset a user's password.
  _i3.Future<bool> resetPassword(
    int userId,
    String newPassword,
  ) => caller.callServerEndpoint<bool>(
    'auth',
    'resetPassword',
    {
      'userId': userId,
      'newPassword': newPassword,
    },
  );

  /// Admin: delete a user account.
  _i3.Future<bool> deleteUser(int userId) => caller.callServerEndpoint<bool>(
    'auth',
    'deleteUser',
    {'userId': userId},
  );

  /// Store the device's FCM token for push notifications.
  /// Called by the Flutter app after Firebase initializes.
  _i3.Future<void> updateFcmToken(
    int userId,
    String token,
  ) => caller.callServerEndpoint<void>(
    'auth',
    'updateFcmToken',
    {
      'userId': userId,
      'token': token,
    },
  );
}

/// Handles ticket comments.
/// Access via `client.comment` on the Flutter client.
/// {@category Endpoint}
class EndpointComment extends _i2.EndpointRef {
  EndpointComment(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'comment';

  /// Get all comments for a ticket.
  _i3.Future<List<_i7.TicketComment>> getComments(int ticketId) =>
      caller.callServerEndpoint<List<_i7.TicketComment>>(
        'comment',
        'getComments',
        {'ticketId': ticketId},
      );

  /// Add a comment to a ticket. Sends push notification to the other party.
  _i3.Future<_i7.TicketComment> addComment(
    int ticketId,
    int userId,
    String commentText,
  ) => caller.callServerEndpoint<_i7.TicketComment>(
    'comment',
    'addComment',
    {
      'ticketId': ticketId,
      'userId': userId,
      'commentText': commentText,
    },
  );
}

/// Handles reference data: categories, assets, departments, emergency contacts.
/// Access via `client.reference` on the Flutter client.
/// {@category Endpoint}
class EndpointReference extends _i2.EndpointRef {
  EndpointReference(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'reference';

  _i3.Future<List<_i8.Category>> getCategories() =>
      caller.callServerEndpoint<List<_i8.Category>>(
        'reference',
        'getCategories',
        {},
      );

  /// Admin: create or update a category.
  _i3.Future<_i8.Category> upsertCategory(_i8.Category cat) =>
      caller.callServerEndpoint<_i8.Category>(
        'reference',
        'upsertCategory',
        {'cat': cat},
      );

  /// Admin: delete a category by id.
  _i3.Future<void> deleteCategory(int id) => caller.callServerEndpoint<void>(
    'reference',
    'deleteCategory',
    {'id': id},
  );

  _i3.Future<List<_i9.Asset>> getAssets() =>
      caller.callServerEndpoint<List<_i9.Asset>>(
        'reference',
        'getAssets',
        {},
      );

  /// Admin: create or update an asset.
  _i3.Future<_i9.Asset> upsertAsset(_i9.Asset asset) =>
      caller.callServerEndpoint<_i9.Asset>(
        'reference',
        'upsertAsset',
        {'asset': asset},
      );

  /// Admin: delete an asset by id.
  _i3.Future<void> deleteAsset(int id) => caller.callServerEndpoint<void>(
    'reference',
    'deleteAsset',
    {'id': id},
  );

  _i3.Future<List<_i10.Department>> getDepartments() =>
      caller.callServerEndpoint<List<_i10.Department>>(
        'reference',
        'getDepartments',
        {},
      );

  /// Admin: create or update a department.
  _i3.Future<_i10.Department> upsertDepartment(_i10.Department dept) =>
      caller.callServerEndpoint<_i10.Department>(
        'reference',
        'upsertDepartment',
        {'dept': dept},
      );

  /// Admin: delete a department by id.
  _i3.Future<void> deleteDepartment(int id) => caller.callServerEndpoint<void>(
    'reference',
    'deleteDepartment',
    {'id': id},
  );

  /// Public: any authenticated user can fetch Emergency Contacts.
  _i3.Future<List<_i11.EmergencyContact>> getEmergencyContacts() =>
      caller.callServerEndpoint<List<_i11.EmergencyContact>>(
        'reference',
        'getEmergencyContacts',
        {},
      );

  /// Admin only: create or update an EmergencyContact.
  _i3.Future<_i11.EmergencyContact> upsertEmergencyContact(
    _i11.EmergencyContact contact,
  ) => caller.callServerEndpoint<_i11.EmergencyContact>(
    'reference',
    'upsertEmergencyContact',
    {'contact': contact},
  );

  /// Admin only: delete an EmergencyContact by id.
  _i3.Future<void> deleteEmergencyContact(int id) =>
      caller.callServerEndpoint<void>(
        'reference',
        'deleteEmergencyContact',
        {'id': id},
      );
}

/// Handles all ticket CRUD operations and workflow.
/// Access via `client.ticket` on the Flutter client.
/// {@category Endpoint}
class EndpointTicket extends _i2.EndpointRef {
  EndpointTicket(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'ticket';

  /// Get tickets filtered by userId and roleId.
  /// roleId: 1=Admin, 2=IT Staff, 3=Customer
  _i3.Future<List<_i12.Ticket>> getTickets(
    int userId,
    int roleId,
  ) => caller.callServerEndpoint<List<_i12.Ticket>>(
    'ticket',
    'getTickets',
    {
      'userId': userId,
      'roleId': roleId,
    },
  );

  /// Get unassigned (Open, no assignee) tickets.
  _i3.Future<List<_i12.Ticket>> getUnassignedTickets() =>
      caller.callServerEndpoint<List<_i12.Ticket>>(
        'ticket',
        'getUnassignedTickets',
        {},
      );

  /// Get a single ticket by ID.
  _i3.Future<_i12.Ticket?> getTicketById(int ticketId) =>
      caller.callServerEndpoint<_i12.Ticket?>(
        'ticket',
        'getTicketById',
        {'ticketId': ticketId},
      );

  /// Create a new ticket. Sends push notification to all Admins.
  _i3.Future<_i12.Ticket> createTicket(
    int requesterId,
    int categoryId,
    String subject,
    String description,
    String priority,
    int? assetId,
  ) => caller.callServerEndpoint<_i12.Ticket>(
    'ticket',
    'createTicket',
    {
      'requesterId': requesterId,
      'categoryId': categoryId,
      'subject': subject,
      'description': description,
      'priority': priority,
      'assetId': assetId,
    },
  );

  /// Assign (or unassign) a ticket to an IT staff member.
  /// Sends push notification to the assigned IT staff.
  _i3.Future<_i12.Ticket?> assignTicket(
    int ticketId,
    int? assigneeId,
  ) => caller.callServerEndpoint<_i12.Ticket?>(
    'ticket',
    'assignTicket',
    {
      'ticketId': ticketId,
      'assigneeId': assigneeId,
    },
  );

  /// Update ticket status. Sends context-driven push notifications.
  _i3.Future<_i12.Ticket?> updateStatus(
    int ticketId,
    String status,
  ) => caller.callServerEndpoint<_i12.Ticket?>(
    'ticket',
    'updateStatus',
    {
      'ticketId': ticketId,
      'status': status,
    },
  );

  /// Propose a deadline for a ticket. Notifies Admins.
  _i3.Future<_i12.Ticket?> proposeDeadline(
    int ticketId,
    int proposedByUserId,
    DateTime proposedDeadline,
  ) => caller.callServerEndpoint<_i12.Ticket?>(
    'ticket',
    'proposeDeadline',
    {
      'ticketId': ticketId,
      'proposedByUserId': proposedByUserId,
      'proposedDeadline': proposedDeadline,
    },
  );

  /// Admin approves or adjusts a proposed deadline. Notifies Requester.
  _i3.Future<_i12.Ticket?> approveDeadline(
    int ticketId,
    String action,
    DateTime? adjustedDeadline,
    String? adminNote,
  ) => caller.callServerEndpoint<_i12.Ticket?>(
    'ticket',
    'approveDeadline',
    {
      'ticketId': ticketId,
      'action': action,
      'adjustedDeadline': adjustedDeadline,
      'adminNote': adminNote,
    },
  );

  /// Requester confirms or rejects the approved deadline.
  _i3.Future<_i12.Ticket?> confirmDeadline(
    int ticketId,
    bool confirmed,
  ) => caller.callServerEndpoint<_i12.Ticket?>(
    'ticket',
    'confirmDeadline',
    {
      'ticketId': ticketId,
      'confirmed': confirmed,
    },
  );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i2.EndpointRef {
  EndpointGreeting(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i3.Future<_i13.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i13.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _i1.Caller(client);
    serverpod_auth_core = _i4.Caller(client);
  }

  late final _i1.Caller serverpod_auth_idp;

  late final _i4.Caller serverpod_auth_core;
}

class Client extends _i2.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i2.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i2.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i14.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    attachment = EndpointAttachment(this);
    auth = EndpointAuth(this);
    comment = EndpointComment(this);
    reference = EndpointReference(this);
    ticket = EndpointTicket(this);
    greeting = EndpointGreeting(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointAttachment attachment;

  late final EndpointAuth auth;

  late final EndpointComment comment;

  late final EndpointReference reference;

  late final EndpointTicket ticket;

  late final EndpointGreeting greeting;

  late final Modules modules;

  @override
  Map<String, _i2.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'attachment': attachment,
    'auth': auth,
    'comment': comment,
    'reference': reference,
    'ticket': ticket,
    'greeting': greeting,
  };

  @override
  Map<String, _i2.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
