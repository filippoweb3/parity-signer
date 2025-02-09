package io.parity.signer.screens.settings.networks.helper

import android.content.res.Configuration
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.dimensionResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import io.parity.signer.R
import io.parity.signer.components.base.ScreenHeaderWithButton
import io.parity.signer.components.base.SecondaryButtonWide
import io.parity.signer.domain.Callback
import io.parity.signer.ui.theme.*

@Composable
internal fun HowUpdateMetadata(
	onClose: Callback,
	onDone: Callback,
	onScanClicked: Callback,
) {
	Column() {
		ScreenHeaderWithButton(
			canProceed = true,
			btnText = stringResource(id = R.string.generic_done),
			onClose = onClose,
			onDone = onDone,
			backNotClose = true,
		)
		Column(
			modifier = Modifier
				.verticalScroll(rememberScrollState())
				.padding(16.dp)
		) {
			Text(
				text = stringResource(R.string.networks_help_screen_2),
				style = SignerTypeface.CaptionM,
				color = MaterialTheme.colors.textSecondary,
				modifier = Modifier.padding(horizontal = 8.dp),
			)
			Text(
				text = stringResource(R.string.networks_help_title_add_metadata),
				style = SignerTypeface.TitleL,
				color = MaterialTheme.colors.primary,
				modifier = Modifier
					.padding(bottom = 16.dp)
					.padding(horizontal = 8.dp),
			)
			Row(
				modifier = Modifier
					.fillMaxWidth(1f)
					.background(
						MaterialTheme.colors.fill12,
						RoundedCornerShape(dimensionResource(id = R.dimen.qrShapeCornerRadius))
					)
					.padding(16.dp)
			) {
				Box(
					modifier = Modifier
						.padding(end = 12.dp)
						.background(
							MaterialTheme.colors.backgroundSystem,
							CircleShape,
						)
						.defaultMinSize(32.dp, 32.dp),

					contentAlignment = Alignment.Center,
				) {
					Text(
						text = stringResource(R.string.step_number_1),
						style = SignerTypeface.BodyL,
						color = MaterialTheme.colors.primary,
					)
				}
				Column() {
					Text(
						text = stringResource(R.string.network_help_metadata_go_portal),
						style = SignerTypeface.BodyL,
						color = MaterialTheme.colors.primary,
						modifier = Modifier.padding(end = 12.dp)
					)
					Text(
						text = getDescriptionForLinks(),
						style = SignerTypeface.BodyM,
						color = MaterialTheme.colors.textSecondary,
						modifier = Modifier.padding(end = 12.dp)
					)
				}
			}

			Spacer(modifier = Modifier.padding(top = 4.dp))

			Row(
				modifier = Modifier
					.fillMaxWidth(1f)
					.background(
						MaterialTheme.colors.fill12,
						RoundedCornerShape(dimensionResource(id = R.dimen.qrShapeCornerRadius))
					)
					.padding(16.dp)
			) {
				Box(
					modifier = Modifier
						.padding(end = 12.dp)
						.background(
							MaterialTheme.colors.backgroundSystem,
							CircleShape,
						)
						.defaultMinSize(32.dp, 32.dp),

					contentAlignment = Alignment.Center,
				) {
					Text(
						text = stringResource(R.string.step_number_2),
						style = SignerTypeface.BodyL,
						color = MaterialTheme.colors.primary,
					)
				}
				Text(
					text = stringResource(R.string.network_help_metadata_choose_networks),
					style = SignerTypeface.BodyL,
					color = MaterialTheme.colors.primary,
					modifier = Modifier.padding(end = 12.dp)
				)
			}

			Spacer(modifier = Modifier.padding(top = 4.dp))

			Column(
				modifier = Modifier
					.fillMaxWidth(1f)
					.background(
						MaterialTheme.colors.fill12,
						RoundedCornerShape(dimensionResource(id = R.dimen.qrShapeCornerRadius))
					)
					.padding(16.dp)
			) {
				Row() {
					Box(
						modifier = Modifier
							.padding(end = 12.dp)
							.background(
								MaterialTheme.colors.backgroundSystem,
								CircleShape,
							)
							.defaultMinSize(32.dp, 32.dp),

						contentAlignment = Alignment.Center,
					) {
						Text(
							text = stringResource(R.string.step_number_3),
							style = SignerTypeface.BodyL,
							color = MaterialTheme.colors.primary,
						)
					}
					Column() {
						Text(
							text = stringResource(R.string.network_help_metadata_go_scan),
							style = SignerTypeface.BodyL,
							color = MaterialTheme.colors.primary,
							modifier = Modifier.padding(end = 12.dp)
						)
					}
				}
				SecondaryButtonWide(
					label = stringResource(R.string.network_help_metadata_scan_cta),
					onClicked = onScanClicked,
					withBackground = true,
					modifier = Modifier.padding(top = 16.dp)
				)
			}
		}
	}
}


@Preview(
	name = "light", group = "general", uiMode = Configuration.UI_MODE_NIGHT_NO,
	showBackground = true, backgroundColor = 0xFFFFFFFF,
)
@Preview(
	name = "dark", group = "general",
	uiMode = Configuration.UI_MODE_NIGHT_YES,
	showBackground = true, backgroundColor = 0xFF000000,
)
@Composable
private fun PreviewHowUpdateMetadata() {
	SignerNewTheme {
		HowUpdateMetadata({}, {}, {})
	}
}
